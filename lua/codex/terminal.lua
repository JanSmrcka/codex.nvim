-- terminal.lua - Terminal buffer and process management
-- Handles creation, toggling, and management of Codex terminal instances

local M = {}

-- Toggle Codex terminal (main function)
-- @param codex_state table The plugin state (instances, current_instance, etc.)
-- @param config table The plugin configuration
function M.toggle(codex_state, config)
  local instance_id = M.get_instance_id(config)
  local bufnr = codex_state.instances[instance_id]

  if bufnr and M.is_valid_terminal_buffer(bufnr) then
    M.handle_existing_instance(codex_state, config, instance_id, bufnr)
  else
    M.create_new_instance(codex_state, config, instance_id)
  end
end

-- Toggle with command variant (--continue, --resume, etc.)
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param variant_name string The variant name (e.g., 'continue', 'resume')
function M.toggle_with_variant(codex_state, config, variant_name)
  local variant = config.command_variants[variant_name]
  if not variant or not variant.enabled then
    vim.notify(
      'codex.nvim: Variant "' .. variant_name .. '" not enabled',
      vim.log.levels.WARN
    )
    return
  end

  -- Temporarily modify config to include variant
  local modified_config = vim.deepcopy(config)
  modified_config._active_variant = variant

  M.toggle(codex_state, modified_config)
end

-- Execute non-interactive command (exec mode)
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param prompt string The command prompt (optional)
function M.exec(codex_state, config, prompt)
  if not prompt or prompt == '' then
    prompt = vim.fn.input('Codex exec: ')
    if not prompt or prompt == '' then
      return
    end
  end

  -- Build exec command
  local cmd = M.build_exec_command(config, prompt)

  -- Create temporary buffer for output
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, 'codex-exec-' .. os.time())

  -- Set buffer options (using new API)
  vim.bo[bufnr].buftype = 'nofile'
  vim.bo[bufnr].bufhidden = 'wipe'

  -- Open in split
  vim.cmd('botright split')
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Run command
  vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        vim.notify('Codex exec completed', vim.log.levels.INFO)
      else
        vim.notify('Codex exec failed with code ' .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

-- Get instance identifier based on git root or cwd
-- @param config table The plugin configuration
-- @return string The instance identifier
function M.get_instance_id(config)
  if config.git.multi_instance then
    if config.git.use_git_root then
      local git = require('codex.git')
      local git_root = git.get_git_root()
      if git_root then
        return git_root
      end
    end
    return vim.fn.getcwd()
  else
    return 'global'
  end
end

-- Check if terminal buffer is valid and running
-- @param bufnr number The buffer number
-- @return boolean True if valid and running
function M.is_valid_terminal_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local ok, buftype = pcall(function()
    return vim.bo[bufnr].buftype
  end)
  if not ok or buftype ~= 'terminal' then
    return false
  end

  -- Check if terminal job is still running
  local ok_var, terminal_job_id = pcall(vim.api.nvim_buf_get_var, bufnr, 'terminal_job_id')
  if not ok_var or not terminal_job_id then
    return false
  end

  local job_status = vim.fn.jobwait({ terminal_job_id }, 0)[1]
  return job_status == -1 -- -1 means still running
end

-- Handle existing instance (toggle visibility)
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param instance_id string The instance identifier
-- @param bufnr number The buffer number
function M.handle_existing_instance(codex_state, config, instance_id, bufnr)
  local win_id = M.find_window_for_buffer(bufnr)

  if win_id then
    -- Buffer is visible, close it
    vim.api.nvim_win_close(win_id, false)
  else
    -- Buffer is hidden, show it
    M.open_terminal_window(bufnr, config)
    codex_state.current_instance = instance_id

    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd('startinsert')
    end
  end
end

-- Create new Codex instance
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param instance_id string The instance identifier
function M.create_new_instance(codex_state, config, instance_id)
  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer name
  local safe_instance_id = instance_id:gsub('[/\\:]', '-')
  vim.api.nvim_buf_set_name(bufnr, 'codex-' .. safe_instance_id)

  -- Set buffer options (using new API)
  vim.bo[bufnr].buflisted = false

  -- Open window
  M.open_terminal_window(bufnr, config)

  -- Build command
  local cmd = M.build_command_with_git_root(config, instance_id)

  -- Start terminal (this automatically sets buftype to 'terminal')
  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, exit_code, _)
      -- Clean up instance on exit
      if codex_state.instances[instance_id] == bufnr then
        codex_state.instances[instance_id] = nil
      end
      if codex_state.current_instance == instance_id then
        codex_state.current_instance = nil
      end
    end,
  })

  if job_id == 0 or job_id == -1 then
    vim.notify('codex.nvim: Failed to start Codex', vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return
  end

  -- Store buffer number
  codex_state.instances[instance_id] = bufnr
  codex_state.current_instance = instance_id

  -- Configure window
  local win_id = vim.api.nvim_get_current_win()
  M.configure_window_options(win_id, config)

  -- Enter insert mode if configured
  if config.window.enter_insert and not config.window.start_in_normal_mode then
    vim.cmd('startinsert')
  end
end

-- Build Codex command with git root handling
-- @param config table The plugin configuration
-- @param instance_id string The instance identifier
-- @return string The complete shell command
function M.build_command_with_git_root(config, instance_id)
  local cmd_parts = {}

  -- Change to git root if needed
  if config.git.use_git_root and instance_id ~= 'global' and instance_id ~= vim.fn.getcwd() then
    table.insert(cmd_parts, config.shell.pushd_cmd .. ' ' .. vim.fn.shellescape(instance_id))
  end

  -- Build base command
  local base_cmd = config.command

  -- Add variant if active
  if config._active_variant then
    base_cmd = base_cmd .. ' ' .. config._active_variant.flags
  end

  table.insert(cmd_parts, base_cmd)

  -- Add popd if we pushed
  if #cmd_parts > 1 then
    table.insert(cmd_parts, config.shell.popd_cmd)
  end

  return table.concat(cmd_parts, config.shell.separator)
end

-- Build exec command
-- @param config table The plugin configuration
-- @param prompt string The command prompt
-- @return string The complete exec command
function M.build_exec_command(config, prompt)
  local cmd_parts = { config.command, 'exec', vim.fn.shellescape(prompt) }
  return table.concat(cmd_parts, ' ')
end

-- Open terminal window (split or float)
-- @param bufnr number The buffer number
-- @param config table The plugin configuration
function M.open_terminal_window(bufnr, config)
  if config.window.position == 'float' then
    M.create_float(bufnr, config)
  else
    M.create_split(bufnr, config)
  end
end

-- Create floating window
-- @param bufnr number The buffer number
-- @param config table The plugin configuration
-- @return number The window ID
function M.create_float(bufnr, config)
  local float_config = config.window.float

  -- Get editor dimensions
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  -- Calculate dimensions
  local width = M.calculate_dimension(float_config.width, editor_width)
  local height = M.calculate_dimension(float_config.height, editor_height)

  -- Calculate position
  local row = M.calculate_position(float_config.row, height, editor_height)
  local col = M.calculate_position(float_config.col, width, editor_width)

  -- Create window
  local win_id = vim.api.nvim_open_win(bufnr, true, {
    relative = float_config.relative,
    width = width,
    height = height,
    row = row,
    col = col,
    border = float_config.border,
    style = 'minimal',
  })

  return win_id
end

-- Create split window
-- @param bufnr number The buffer number
-- @param config table The plugin configuration
-- @return number The window ID
function M.create_split(bufnr, config)
  local position = config.window.position

  -- Build split command
  local split_cmd
  if position:match('vertical') then
    split_cmd = 'vsplit'
  else
    split_cmd = 'split'
  end

  if position:match('botright') then
    split_cmd = 'botright ' .. split_cmd
  elseif position:match('topleft') then
    split_cmd = 'topleft ' .. split_cmd
  end

  -- Execute split
  vim.cmd(split_cmd)
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Resize
  local is_vertical = position:match('vertical') ~= nil
  if is_vertical then
    local width = math.floor(vim.o.columns * config.window.split_ratio)
    vim.cmd('vertical resize ' .. width)
  else
    local height = math.floor(vim.o.lines * config.window.split_ratio)
    vim.cmd('resize ' .. height)
  end

  return vim.api.nvim_get_current_win()
end

-- Configure window options (hide numbers, signcolumn, etc.)
-- @param win_id number The window ID
-- @param config table The plugin configuration
function M.configure_window_options(win_id, config)
  if config.window.hide_numbers then
    vim.wo[win_id].number = false
    vim.wo[win_id].relativenumber = false
  end

  if config.window.hide_signcolumn then
    vim.wo[win_id].signcolumn = 'no'
  end
end

-- Calculate dimension from percentage or absolute value
-- @param value string|number The dimension value
-- @param max_value number The maximum value
-- @return number The calculated dimension
function M.calculate_dimension(value, max_value)
  if type(value) == 'string' and value:match('%%$') then
    local percent = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_value * percent / 100)
  else
    return value
  end
end

-- Calculate position from 'center', percentage, or absolute value
-- @param value string|number The position value
-- @param size number The size of the element
-- @param max_size number The maximum size
-- @return number The calculated position
function M.calculate_position(value, size, max_size)
  if value == 'center' then
    return math.floor((max_size - size) / 2)
  elseif type(value) == 'string' and value:match('%%$') then
    local percent = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_size * percent / 100)
  else
    return value
  end
end

-- Find window displaying a buffer
-- @param bufnr number The buffer number
-- @return number|nil The window ID, or nil if not found
function M.find_window_for_buffer(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
  return nil
end

-- Force insert mode in terminal
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
function M.force_insert_mode(codex_state, config)
  local current_buf = vim.api.nvim_get_current_buf()

  -- Check if current buffer is a Codex terminal
  local is_codex_terminal = false
  for _, bufnr in pairs(codex_state.instances) do
    if current_buf == bufnr then
      is_codex_terminal = true
      break
    end
  end

  if not is_codex_terminal then
    return
  end

  -- Enter insert mode if configured
  if config.window.enter_insert and vim.api.nvim_get_mode().mode ~= 'i' then
    vim.cmd('startinsert')
  end
end

return M
