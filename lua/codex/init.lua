-- init.lua - Main entry point for codex.nvim
-- Exposes the public API and orchestrates plugin initialization

local M = {}

-- Plugin state (global singleton)
M.codex = {
  instances = {}, -- { [instance_id] = buffer_number }
  current_instance = nil, -- Current instance identifier
  saved_updatetime = nil, -- Stored original updatetime
}

-- Configuration (initialized in setup())
M.config = nil

-- Setup function (called by user in init.lua/init.vim)
-- @param user_config table Optional user configuration
function M.setup(user_config)
  -- Load modules
  local config = require('codex.config')
  local file_refresh = require('codex.file_refresh')
  local commands = require('codex.commands')
  local keymaps = require('codex.keymaps')
  local mcp = require('codex.mcp')

  -- Parse and validate configuration
  M.config = config.parse_config(user_config or {})

  -- Enable autoread for file monitoring
  vim.o.autoread = true

  -- Setup file refresh monitoring
  file_refresh.setup(M, M.config)

  -- Register commands
  commands.register_commands(M)

  -- Register keymaps
  keymaps.register_keymaps(M, M.config)

  -- Setup MCP if configured
  if M.config.mcp.enable then
    mcp.setup(M.config)
  end
end

-- Toggle Codex terminal (main command)
function M.toggle()
  local terminal = require('codex.terminal')
  terminal.toggle(M.codex, M.config)
end

-- Toggle with command variant (--continue, --exec, etc.)
-- @param variant_name string The variant name
function M.toggle_with_variant(variant_name)
  local terminal = require('codex.terminal')
  terminal.toggle_with_variant(M.codex, M.config, variant_name)
end

-- Execute non-interactive command
-- @param prompt string Optional command prompt
function M.exec(prompt)
  local terminal = require('codex.terminal')
  terminal.exec(M.codex, M.config, prompt)
end

-- Send current buffer to Codex
function M.send_buffer()
  local context = require('codex.context')
  context.send_buffer(M.codex, M.config)
end

-- Send visual selection to Codex
function M.send_selection()
  local context = require('codex.context')
  context.send_selection(M.codex, M.config)
end

-- Send file to Codex
-- @param filepath string The file path
function M.send_file(filepath)
  local context = require('codex.context')
  context.send_file(M.codex, M.config, filepath)
end

-- Force terminal into insert mode
function M.force_insert_mode()
  local terminal = require('codex.terminal')
  terminal.force_insert_mode(M.codex, M.config)
end

-- Get plugin version
-- @return string The version string
function M.get_version()
  local version = require('codex.version')
  return version.get_version()
end

-- Get detailed version information
-- @return table Version information
function M.get_version_info()
  local version = require('codex.version')
  return version.get_version_info()
end

-- Get current configuration
-- @return table The current configuration
function M.get_config()
  return M.config
end

-- Get plugin state
-- @return table The current plugin state
function M.get_state()
  return M.codex
end

-- Check if Codex is available
-- @return boolean True if Codex CLI is available
function M.is_codex_available()
  local handle = io.popen('which codex 2>/dev/null')
  if not handle then
    return false
  end

  local result = handle:read('*a')
  handle:close()

  return result ~= ''
end

-- Get list of active instances
-- @return table Array of instance information
function M.get_instances()
  local instances = {}

  for instance_id, bufnr in pairs(M.codex.instances) do
    local terminal = require('codex.terminal')
    local is_valid = terminal.is_valid_terminal_buffer(bufnr)
    local is_visible = terminal.find_window_for_buffer(bufnr) ~= nil

    table.insert(instances, {
      id = instance_id,
      bufnr = bufnr,
      valid = is_valid,
      visible = is_visible,
      current = instance_id == M.codex.current_instance,
    })
  end

  return instances
end

-- Close a specific instance
-- @param instance_id string The instance identifier
function M.close_instance(instance_id)
  local bufnr = M.codex.instances[instance_id]
  if not bufnr then
    vim.notify('Instance not found: ' .. instance_id, vim.log.levels.WARN)
    return
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end

  M.codex.instances[instance_id] = nil
  if M.codex.current_instance == instance_id then
    M.codex.current_instance = nil
  end
end

-- Close all instances
function M.close_all_instances()
  for instance_id, bufnr in pairs(M.codex.instances) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  M.codex.instances = {}
  M.codex.current_instance = nil
end

return M
