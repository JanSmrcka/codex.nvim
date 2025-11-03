-- version.lua - Version information for codex.nvim
-- Provides version tracking and retrieval

local M = {}

-- Plugin version (semantic versioning)
M.VERSION = '0.1.0'

-- Get the current version
-- @return string The version string
function M.get_version()
  return M.VERSION
end

-- Get detailed version information
-- @return table Version information with additional metadata
function M.get_version_info()
  return {
    version = M.VERSION,
    name = 'codex.nvim',
    description = 'Seamless OpenAI Codex CLI integration for Neovim',
  }
end

return M
