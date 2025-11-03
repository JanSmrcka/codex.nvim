local M = {}

function M.check()
  vim.health.start("codex.nvim")
  
  -- Check if Neovim version is compatible
  local nvim_version = vim.version()
  if vim.version.cmp(nvim_version, {0, 9, 0}) >= 0 then
    vim.health.ok("Neovim version is compatible (>= 0.9.0)")
  else
    vim.health.warn("Neovim version is older than 0.9.0. Some features may not work correctly.")
  end
  
  -- Check if plugin is loaded
  local ok, codex = pcall(require, "codex")
  if ok then
    vim.health.ok("codex.nvim module loaded successfully")
    
    -- Check if plugin is enabled
    if codex.is_enabled() then
      vim.health.ok("Plugin is enabled")
    else
      vim.health.warn("Plugin is disabled")
    end
  else
    vim.health.error("Failed to load codex.nvim module: " .. tostring(codex))
  end
end

return M
