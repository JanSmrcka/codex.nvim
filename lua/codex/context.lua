-- context.lua - Context sending utilities
-- Handles sending buffer, selection, and file content to Codex terminal

local M = {}

-- Send current buffer to Codex
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
function M.send_buffer(codex_state, config)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Check max_lines limit
  if #lines > config.context.max_lines then
    vim.notify(
      string.format(
        'Buffer has %d lines, exceeds max_lines (%d)',
        #lines,
        config.context.max_lines
      ),
      vim.log.levels.WARN
    )
    return
  end

  -- Build context
  local context = M.build_context(lines, filepath, config)

  -- Send to Codex
  M.send_to_codex(codex_state, config, context)
end

-- Send visual selection to Codex
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
function M.send_selection(codex_state, config)
  -- Get visual selection
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local bufnr = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Build context
  local context = M.build_context(lines, filepath, config, start_line, end_line)

  -- Send to Codex
  M.send_to_codex(codex_state, config, context)
end

-- Send specific file to Codex
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param filepath string The file path
function M.send_file(codex_state, config, filepath)
  -- Expand path
  filepath = vim.fn.expand(filepath)

  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify('File not readable: ' .. filepath, vim.log.levels.ERROR)
    return
  end

  -- Read file
  local lines = vim.fn.readfile(filepath)

  -- Check max_lines limit
  if #lines > config.context.max_lines then
    vim.notify(
      string.format('File has %d lines, exceeds max_lines (%d)', #lines, config.context.max_lines),
      vim.log.levels.WARN
    )
    return
  end

  -- Build context
  local context = M.build_context(lines, filepath, config)

  -- Send to Codex
  M.send_to_codex(codex_state, config, context)
end

-- Build context string with formatting
-- @param lines table Array of lines
-- @param filepath string The file path
-- @param config table The plugin configuration
-- @param start_line number Optional start line number
-- @param end_line number Optional end line number
-- @return string The formatted context
function M.build_context(lines, filepath, config, start_line, end_line)
  local parts = {}

  if config.context.include_filepath and filepath ~= '' then
    if start_line and end_line then
      table.insert(
        parts,
        string.format('File: %s (lines %d-%d)', filepath, start_line, end_line)
      )
    else
      table.insert(parts, 'File: ' .. filepath)
    end
    table.insert(parts, '')
  end

  -- Add code fence for markdown formatting
  local ext = vim.fn.fnamemodify(filepath, ':e')
  if ext ~= '' then
    table.insert(parts, '```' .. ext)
  else
    table.insert(parts, '```')
  end

  for _, line in ipairs(lines) do
    table.insert(parts, line)
  end

  table.insert(parts, '```')

  return table.concat(parts, '\n')
end

-- Send context to Codex terminal
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
-- @param context string The context string
function M.send_to_codex(codex_state, config, context)
  -- Get current instance
  local instance_id = codex_state.current_instance
  if not instance_id then
    vim.notify('No active Codex instance', vim.log.levels.WARN)
    return
  end

  local bufnr = codex_state.instances[instance_id]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify('Codex terminal not available', vim.log.levels.WARN)
    return
  end

  -- Send based on method
  local method = config.context.method

  if method == 'stdin' then
    M.send_via_stdin(bufnr, context)
  elseif method == 'clipboard' then
    M.send_via_clipboard(context)
  elseif method == 'file' then
    M.send_via_file(bufnr, context)
  else
    vim.notify('Unknown context method: ' .. method, vim.log.levels.ERROR)
  end
end

-- Send via stdin (paste into terminal)
-- @param bufnr number The terminal buffer number
-- @param context string The context string
function M.send_via_stdin(bufnr, context)
  -- Get terminal job ID
  local ok, job_id = pcall(vim.api.nvim_buf_get_var, bufnr, 'terminal_job_id')
  if not ok or not job_id then
    vim.notify('Terminal job not found', vim.log.levels.ERROR)
    return
  end

  -- Split context into lines and send
  local lines = vim.split(context, '\n', { plain = true })
  for _, line in ipairs(lines) do
    vim.fn.chansend(job_id, line .. '\n')
  end

  vim.notify('Context sent to Codex', vim.log.levels.INFO)
end

-- Send via clipboard (copy to clipboard, user pastes)
-- @param context string The context string
function M.send_via_clipboard(context)
  vim.fn.setreg('+', context)
  vim.notify('Context copied to clipboard. Paste into Codex terminal.', vim.log.levels.INFO)
end

-- Send via temporary file
-- @param bufnr number The terminal buffer number
-- @param context string The context string
function M.send_via_file(bufnr, context)
  -- Create temp file
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.split(context, '\n', { plain = true }), tmpfile)

  -- Get terminal job ID
  local ok, job_id = pcall(vim.api.nvim_buf_get_var, bufnr, 'terminal_job_id')
  if not ok or not job_id then
    vim.notify('Terminal job not found', vim.log.levels.ERROR)
    return
  end

  -- Send command to read file
  local cmd = string.format('cat %s\n', vim.fn.shellescape(tmpfile))
  vim.fn.chansend(job_id, cmd)

  -- Schedule file deletion
  vim.defer_fn(function()
    vim.fn.delete(tmpfile)
  end, 5000)

  vim.notify('Context sent via file', vim.log.levels.INFO)
end

return M
