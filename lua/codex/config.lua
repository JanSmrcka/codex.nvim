-- config.lua - Configuration management for codex.nvim
-- Handles default configuration, parsing, validation, and merging

local M = {}

-- Default configuration
M.default_config = {
  -- Terminal window configuration
  window = {
    split_ratio = 0.3, -- Size of split (0.0-1.0)
    position = 'botright', -- 'botright', 'topleft', 'vertical', 'float'
    enter_insert = true, -- Enter insert mode when opening
    start_in_normal_mode = false, -- Start in normal mode instead
    hide_numbers = true, -- Hide line numbers in terminal
    hide_signcolumn = true, -- Hide sign column

    -- Floating window specific options
    float = {
      width = '80%', -- Width (number or percentage)
      height = '80%', -- Height (number or percentage)
      row = 'center', -- Row position ('center' or number/percentage)
      col = 'center', -- Col position ('center' or number/percentage)
      border = 'rounded', -- Border style
      relative = 'editor', -- Relative to 'editor' or 'cursor'
    },
  },

  -- File refresh configuration
  refresh = {
    enable = true, -- Enable file monitoring
    updatetime = 100, -- Vim updatetime while terminal active
    timer_interval = 1000, -- Polling interval (ms)
    show_notifications = false, -- Notify on file changes
  },

  -- Git integration
  git = {
    use_git_root = true, -- Change to git root when opening
    multi_instance = true, -- One instance per git root
  },

  -- Shell command configuration
  shell = {
    separator = ' && ', -- Command separator
    pushd_cmd = 'pushd', -- Directory change command
    popd_cmd = 'popd', -- Directory restore command
  },

  -- Base Codex command
  command = 'codex',

  -- Command variants
  command_variants = {
    continue = {
      enabled = true,
      flags = '--continue',
    },
    resume = {
      enabled = true,
      flags = '--resume',
    },
    verbose = {
      enabled = true,
      flags = '--verbose',
    },
    exec = {
      enabled = true,
      flags = 'exec', -- Subcommand, not flag
    },
  },

  -- Context management
  context = {
    method = 'stdin', -- 'stdin', 'clipboard', 'file'
    auto_send_on_open = false, -- Auto-send current buffer on open
    include_filepath = true, -- Include file path in context
    max_lines = 10000, -- Max lines to send
  },

  -- MCP integration
  mcp = {
    enable = false, -- Enable MCP integration
    config_path = nil, -- Path to MCP config (default: ~/.codex/config.toml)
    show_status = true, -- Show MCP status in terminal
  },

  -- Keyboard mappings
  keymaps = {
    toggle = {
      normal = '<C-,>',
      terminal = '<C-,>',
      variants = {
        continue = '<leader>cc',
        resume = '<leader>cr',
        verbose = '<leader>cv',
        exec = '<leader>cx',
      },
    },
    context = {
      send_buffer = '<leader>cb',
      send_selection = '<leader>cs',
    },
    window_navigation = {
      enable = true,
      left = '<C-h>',
      down = '<C-j>',
      up = '<C-k>',
      right = '<C-l>',
    },
    scrolling = {
      enable = true,
      page_up = '<C-b>',
      page_down = '<C-f>',
    },
  },
}

-- Validation functions

local function validate_window_config(config)
  if type(config.window) ~= 'table' then
    return false, 'window must be a table'
  end

  local split_ratio = config.window.split_ratio
  if type(split_ratio) ~= 'number' or split_ratio <= 0 or split_ratio >= 1 then
    return false, 'window.split_ratio must be between 0 and 1'
  end

  local valid_positions = { 'botright', 'topleft', 'vertical', 'float' }
  if not vim.tbl_contains(valid_positions, config.window.position) then
    return false, 'window.position must be one of: ' .. table.concat(valid_positions, ', ')
  end

  return true
end

local function validate_float_config(config)
  if type(config.window.float) ~= 'table' then
    return false, 'window.float must be a table'
  end

  local valid_borders = { 'none', 'single', 'double', 'rounded', 'solid', 'shadow' }
  if not vim.tbl_contains(valid_borders, config.window.float.border) then
    return false, 'window.float.border must be one of: ' .. table.concat(valid_borders, ', ')
  end

  local valid_relative = { 'editor', 'cursor' }
  if not vim.tbl_contains(valid_relative, config.window.float.relative) then
    return false, 'window.float.relative must be one of: ' .. table.concat(valid_relative, ', ')
  end

  return true
end

local function validate_refresh_config(config)
  if type(config.refresh) ~= 'table' then
    return false, 'refresh must be a table'
  end

  if type(config.refresh.updatetime) ~= 'number' or config.refresh.updatetime < 50 then
    return false, 'refresh.updatetime must be a number >= 50'
  end

  if type(config.refresh.timer_interval) ~= 'number' or config.refresh.timer_interval < 100 then
    return false, 'refresh.timer_interval must be a number >= 100'
  end

  return true
end

local function validate_git_config(config)
  if type(config.git) ~= 'table' then
    return false, 'git must be a table'
  end

  if type(config.git.use_git_root) ~= 'boolean' then
    return false, 'git.use_git_root must be a boolean'
  end

  if type(config.git.multi_instance) ~= 'boolean' then
    return false, 'git.multi_instance must be a boolean'
  end

  return true
end

local function validate_shell_config(config)
  if type(config.shell) ~= 'table' then
    return false, 'shell must be a table'
  end

  if type(config.shell.separator) ~= 'string' then
    return false, 'shell.separator must be a string'
  end

  if type(config.shell.pushd_cmd) ~= 'string' then
    return false, 'shell.pushd_cmd must be a string'
  end

  if type(config.shell.popd_cmd) ~= 'string' then
    return false, 'shell.popd_cmd must be a string'
  end

  return true
end

local function validate_command_config(config)
  if type(config.command) ~= 'string' or config.command == '' then
    return false, 'command must be a non-empty string'
  end

  if type(config.command_variants) ~= 'table' then
    return false, 'command_variants must be a table'
  end

  return true
end

local function validate_context_config(config)
  if type(config.context) ~= 'table' then
    return false, 'context must be a table'
  end

  local valid_methods = { 'stdin', 'clipboard', 'file' }
  if not vim.tbl_contains(valid_methods, config.context.method) then
    return false, 'context.method must be one of: ' .. table.concat(valid_methods, ', ')
  end

  if type(config.context.max_lines) ~= 'number' or config.context.max_lines < 1 then
    return false, 'context.max_lines must be a positive number'
  end

  return true
end

local function validate_mcp_config(config)
  if type(config.mcp) ~= 'table' then
    return false, 'mcp must be a table'
  end

  if config.mcp.config_path and type(config.mcp.config_path) ~= 'string' then
    return false, 'mcp.config_path must be a string or nil'
  end

  return true
end

local function validate_keymaps_config(config)
  if type(config.keymaps) ~= 'table' then
    return false, 'keymaps must be a table'
  end

  -- Basic structure validation
  if type(config.keymaps.toggle) ~= 'table' then
    return false, 'keymaps.toggle must be a table'
  end

  if type(config.keymaps.context) ~= 'table' then
    return false, 'keymaps.context must be a table'
  end

  return true
end

-- Validate entire configuration
local function validate_config(config)
  local validators = {
    validate_window_config,
    validate_float_config,
    validate_refresh_config,
    validate_git_config,
    validate_shell_config,
    validate_command_config,
    validate_context_config,
    validate_mcp_config,
    validate_keymaps_config,
  }

  for _, validator in ipairs(validators) do
    local valid, err = validator(config)
    if not valid then
      return false, err
    end
  end

  return true
end

-- Parse and validate user configuration
-- @param user_config table User-provided configuration
-- @return table The validated and merged configuration
function M.parse_config(user_config)
  user_config = user_config or {}

  -- Deep merge user config with defaults
  local config = vim.tbl_deep_extend('force', {}, M.default_config, user_config)

  -- Validate
  local valid, err = validate_config(config)
  if not valid then
    vim.notify(
      'codex.nvim: Invalid configuration - ' .. err .. '. Using defaults.',
      vim.log.levels.ERROR
    )
    return vim.deepcopy(M.default_config) -- Fallback to safe defaults
  end

  return config
end

-- Get a specific configuration value
-- @param config table The configuration table
-- @param path string Dot-separated path (e.g., 'window.position')
-- @return any The configuration value
function M.get_config_value(config, path)
  local keys = vim.split(path, '.', { plain = true })
  local value = config

  for _, key in ipairs(keys) do
    if type(value) ~= 'table' then
      return nil
    end
    value = value[key]
  end

  return value
end

return M
