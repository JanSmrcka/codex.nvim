local M = {}

-- Default configuration
local default_config = {
  enabled = true,
  debug = false,
}

-- Current configuration
local config = vim.deepcopy(default_config)

-- Setup function to initialize the plugin
function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default_config, user_config)
  
  if config.debug then
    print("codex.nvim: Plugin initialized with config:", vim.inspect(config))
  end
end

-- Get current configuration
function M.get_config()
  return vim.deepcopy(config)
end

-- Check if plugin is enabled
function M.is_enabled()
  return config.enabled
end

-- Enable the plugin
function M.enable()
  config.enabled = true
end

-- Disable the plugin
function M.disable()
  config.enabled = false
end

return M
