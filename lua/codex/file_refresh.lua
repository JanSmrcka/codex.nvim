-- file_refresh.lua - File change detection and auto-reloading
-- Monitors files for changes made by Codex and automatically reloads them

local M = {}

local refresh_timer = nil

-- Setup file refresh monitoring
-- @param plugin_state table The plugin state
-- @param config table The plugin configuration
function M.setup(plugin_state, config)
  if not config.refresh.enable then
    return
  end

  -- Setup autocommands for file change detection
  M.setup_file_change_detection(config)

  -- Setup periodic refresh timer
  M.setup_refresh_timer(plugin_state, config)

  -- Setup updatetime management
  M.setup_updatetime_management(plugin_state, config)
end

-- Setup file change detection autocommands
-- @param config table The plugin configuration
function M.setup_file_change_detection(config)
  local augroup = vim.api.nvim_create_augroup('CodexFileRefresh', { clear = true })

  local events = {
    'CursorHold',
    'CursorHoldI',
    'FocusGained',
    'BufEnter',
    'WinEnter',
  }

  vim.api.nvim_create_autocmd(events, {
    group = augroup,
    callback = function()
      -- Only check if file is readable
      if vim.fn.filereadable(vim.fn.expand('%')) == 1 then
        vim.cmd('silent! checktime')

        if config.refresh.show_notifications then
          -- Note: Vim will show its own message on file change
          -- This is just to add custom notification if desired
        end
      end
    end,
  })
end

-- Setup periodic refresh timer
-- @param plugin_state table The plugin state
-- @param config table The plugin configuration
function M.setup_refresh_timer(plugin_state, config)
  refresh_timer = vim.loop.new_timer()

  refresh_timer:start(
    0,
    config.refresh.timer_interval,
    vim.schedule_wrap(function()
      -- Only refresh if Codex terminal is visible
      if M.is_codex_visible(plugin_state) then
        vim.cmd('silent! checktime')
      end
    end)
  )
end

-- Check if any Codex terminal is visible
-- @param plugin_state table The plugin state
-- @return boolean True if any Codex terminal is visible
function M.is_codex_visible(plugin_state)
  for _, bufnr in pairs(plugin_state.codex.instances) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
          return true
        end
      end
    end
  end
  return false
end

-- Setup updatetime management (optimize while terminal is active)
-- @param plugin_state table The plugin state
-- @param config table The plugin configuration
function M.setup_updatetime_management(plugin_state, config)
  local augroup = vim.api.nvim_create_augroup('CodexUpdateTime', { clear = true })

  -- Save original updatetime and set shorter value when terminal opens
  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Check if this is a Codex terminal
      local is_codex = false
      for _, codex_bufnr in pairs(plugin_state.codex.instances) do
        if bufnr == codex_bufnr then
          is_codex = true
          break
        end
      end

      if is_codex then
        -- Save original updatetime
        if not plugin_state.codex.saved_updatetime then
          plugin_state.codex.saved_updatetime = vim.o.updatetime
        end

        -- Set shorter updatetime for faster change detection
        vim.o.updatetime = config.refresh.updatetime
      end
    end,
  })

  -- Restore original updatetime when all terminals are closed
  vim.api.nvim_create_autocmd('BufDelete', {
    group = augroup,
    callback = function()
      vim.schedule(function()
        if not M.is_codex_visible(plugin_state) and plugin_state.codex.saved_updatetime then
          vim.o.updatetime = plugin_state.codex.saved_updatetime
          plugin_state.codex.saved_updatetime = nil
        end
      end)
    end,
  })
end

-- Cleanup on plugin unload
function M.cleanup()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

return M
