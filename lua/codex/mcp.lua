-- mcp.lua - Model Context Protocol (MCP) integration
-- Provides integration with MCP servers for extended functionality

local M = {}

-- Setup MCP integration
-- @param config table The plugin configuration
function M.setup(config)
  if not config.mcp.enable then
    return
  end

  -- Read MCP config
  local mcp_config_path = config.mcp.config_path or M.get_default_config_path()
  local mcp_servers = M.parse_mcp_config(mcp_config_path)

  if not mcp_servers or #mcp_servers == 0 then
    if config.mcp.show_status then
      vim.notify('codex.nvim: No MCP servers configured', vim.log.levels.INFO)
    end
    return
  end

  -- Register commands
  M.register_mcp_commands(mcp_servers)

  -- Show status if configured
  if config.mcp.show_status then
    vim.notify(
      string.format('codex.nvim: %d MCP server(s) available', #mcp_servers),
      vim.log.levels.INFO
    )
  end
end

-- Get default MCP config path
-- @return string The default config path
function M.get_default_config_path()
  local home = vim.fn.expand('~')
  return home .. '/.codex/config.toml'
end

-- Parse MCP config file (TOML format)
-- @param config_path string The path to the config file
-- @return table Array of server configurations
function M.parse_mcp_config(config_path)
  if vim.fn.filereadable(config_path) == 0 then
    return {}
  end

  -- Read and parse TOML (simple parsing, may need toml library for complex configs)
  local lines = vim.fn.readfile(config_path)
  local servers = {}
  local current_server = nil

  for _, line in ipairs(lines) do
    -- Skip comments and empty lines
    if line:match('^%s*#') or line:match('^%s*$') then
      goto continue
    end

    -- Match server sections: [mcp.servers.servername]
    local server_name = line:match('%[mcp%.servers%.([^%]]+)%]')
    if server_name then
      current_server = {
        name = server_name,
        enabled = true,
        config = {},
      }
      table.insert(servers, current_server)
      goto continue
    end

    -- Parse key-value pairs
    if current_server then
      local key, value = line:match('^%s*([^=]+)%s*=%s*(.+)%s*$')
      if key and value then
        -- Remove quotes from string values
        value = value:gsub('^"(.-)"$', '%1')
        value = value:gsub("^'(.-)'$", '%1')

        -- Parse boolean values
        if value == 'true' then
          value = true
        elseif value == 'false' then
          value = false
        end

        current_server.config[key] = value
      end
    end

    ::continue::
  end

  -- Filter enabled servers
  local enabled_servers = {}
  for _, server in ipairs(servers) do
    if server.enabled then
      table.insert(enabled_servers, server)
    end
  end

  return enabled_servers
end

-- Register MCP-related commands
-- @param servers table Array of MCP server configurations
function M.register_mcp_commands(servers)
  -- List MCP servers
  vim.api.nvim_create_user_command('CodexMcpList', function()
    local lines = { 'MCP Servers:' }
    for _, server in ipairs(servers) do
      local status = server.enabled and '✓' or '✗'
      table.insert(lines, string.format('  %s %s', status, server.name))
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, {
    desc = 'List MCP servers',
  })

  -- Show MCP server info
  vim.api.nvim_create_user_command('CodexMcpInfo', function(opts)
    local server_name = opts.args
    if not server_name or server_name == '' then
      vim.notify('Usage: :CodexMcpInfo <server_name>', vim.log.levels.ERROR)
      return
    end

    local server = nil
    for _, s in ipairs(servers) do
      if s.name == server_name then
        server = s
        break
      end
    end

    if not server then
      vim.notify('MCP server not found: ' .. server_name, vim.log.levels.ERROR)
      return
    end

    local lines = { 'MCP Server: ' .. server.name, '' }
    table.insert(lines, 'Configuration:')
    for key, value in pairs(server.config) do
      table.insert(lines, string.format('  %s = %s', key, tostring(value)))
    end

    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, {
    nargs = 1,
    desc = 'Show MCP server information',
  })
end

-- Check if MCP is enabled
-- @param config table The plugin configuration
-- @return boolean True if MCP is enabled
function M.is_enabled(config)
  return config.mcp.enable
end

-- Get list of available MCP servers
-- @param config table The plugin configuration
-- @return table Array of server names
function M.get_available_servers(config)
  if not config.mcp.enable then
    return {}
  end

  local mcp_config_path = config.mcp.config_path or M.get_default_config_path()
  local servers = M.parse_mcp_config(mcp_config_path)

  local server_names = {}
  for _, server in ipairs(servers) do
    table.insert(server_names, server.name)
  end

  return server_names
end

return M
