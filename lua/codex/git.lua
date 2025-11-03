-- git.lua - Git repository detection and integration
-- Provides functions to detect and work with git repositories

local M = {}

-- Get git root directory for current buffer or working directory
-- @return string|nil The git root path, or nil if not in a git repository
function M.get_git_root()
  local current_file = vim.fn.expand('%:p')
  local current_dir

  if current_file == '' then
    current_dir = vim.fn.getcwd()
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Check if we're in a git repository
  local cmd = string.format(
    'cd %s && git rev-parse --is-inside-work-tree 2>/dev/null',
    vim.fn.shellescape(current_dir)
  )
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local result = handle:read('*a')
  handle:close()

  if result:match('true') then
    -- Get git root
    cmd = string.format(
      'cd %s && git rev-parse --show-toplevel',
      vim.fn.shellescape(current_dir)
    )
    handle = io.popen(cmd)
    if not handle then
      return nil
    end

    local git_root = handle:read('*a')
    handle:close()

    -- Trim whitespace and return
    return git_root:gsub('[%s\n\r]*$', '')
  end

  return nil
end

-- Check if a directory is inside a git repository
-- @param dir string The directory path to check
-- @return boolean True if inside a git repository
function M.is_git_repo(dir)
  dir = dir or vim.fn.getcwd()
  local cmd = string.format(
    'cd %s && git rev-parse --is-inside-work-tree 2>/dev/null',
    vim.fn.shellescape(dir)
  )
  local handle = io.popen(cmd)
  if not handle then
    return false
  end

  local result = handle:read('*a')
  handle:close()

  return result:match('true') ~= nil
end

-- Get the current git branch name
-- @return string|nil The branch name, or nil if not in a git repository
function M.get_branch_name()
  local git_root = M.get_git_root()
  if not git_root then
    return nil
  end

  local cmd = string.format(
    'cd %s && git rev-parse --abbrev-ref HEAD 2>/dev/null',
    vim.fn.shellescape(git_root)
  )
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local branch = handle:read('*a')
  handle:close()

  return branch:gsub('[%s\n\r]*$', '')
end

return M
