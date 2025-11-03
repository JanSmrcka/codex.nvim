-- keymaps.lua - Keyboard binding management
-- Registers and manages all keyboard shortcuts for the plugin

local M = {}

-- Register all plugin keymaps
-- @param plugin table The plugin instance (with all methods)
-- @param config table The plugin configuration
function M.register_keymaps(plugin, config)
  M.setup_toggle_keymaps(plugin, config)
  M.setup_variant_keymaps(plugin, config)
  M.setup_context_keymaps(plugin, config)
  M.setup_terminal_navigation(plugin, config)
  M.setup_whichkey_integration(config)
end

-- Setup main toggle keymaps
-- @param plugin table The plugin instance
-- @param config table The plugin configuration
function M.setup_toggle_keymaps(plugin, config)
  local toggle_config = config.keymaps.toggle

  if toggle_config.normal then
    vim.keymap.set('n', toggle_config.normal, function()
      plugin.toggle()
    end, { desc = 'Toggle Codex', silent = true })
  end

  if toggle_config.terminal then
    vim.keymap.set('t', toggle_config.terminal, function()
      plugin.toggle()
    end, { desc = 'Toggle Codex', silent = true })
  end
end

-- Setup variant keymaps
-- @param plugin table The plugin instance
-- @param config table The plugin configuration
function M.setup_variant_keymaps(plugin, config)
  local variants = config.keymaps.toggle.variants

  for variant_name, keymap in pairs(variants) do
    if keymap and config.command_variants[variant_name].enabled then
      vim.keymap.set('n', keymap, function()
        plugin.toggle_with_variant(variant_name)
      end, { desc = 'Codex ' .. variant_name, silent = true })
    end
  end
end

-- Setup context sending keymaps
-- @param plugin table The plugin instance
-- @param config table The plugin configuration
function M.setup_context_keymaps(plugin, config)
  local context_config = config.keymaps.context

  if context_config.send_buffer then
    vim.keymap.set('n', context_config.send_buffer, function()
      plugin.send_buffer()
    end, { desc = 'Send buffer to Codex', silent = true })
  end

  if context_config.send_selection then
    vim.keymap.set('v', context_config.send_selection, function()
      plugin.send_selection()
    end, { desc = 'Send selection to Codex', silent = true })
  end
end

-- Setup terminal window navigation
-- @param plugin table The plugin instance
-- @param config table The plugin configuration
function M.setup_terminal_navigation(plugin, config)
  if not config.keymaps.window_navigation.enable then
    return
  end

  local nav = config.keymaps.window_navigation
  local scroll = config.keymaps.scrolling

  local augroup = vim.api.nvim_create_augroup('CodexKeymaps', { clear = true })

  -- Auto-enter insert mode in terminal
  local events = { 'WinEnter', 'BufEnter', 'FocusGained', 'CmdlineLeave' }
  vim.api.nvim_create_autocmd(events, {
    group = augroup,
    callback = function()
      vim.schedule(function()
        plugin.force_insert_mode()
      end)
    end,
  })

  -- Window navigation from terminal mode
  vim.keymap.set('t', nav.left, '<C-\\><C-n><C-w>h', { desc = 'Move to left window', silent = true })
  vim.keymap.set(
    't',
    nav.down,
    '<C-\\><C-n><C-w>j',
    { desc = 'Move to below window', silent = true }
  )
  vim.keymap.set(
    't',
    nav.up,
    '<C-\\><C-n><C-w>k',
    { desc = 'Move to above window', silent = true }
  )
  vim.keymap.set(
    't',
    nav.right,
    '<C-\\><C-n><C-w>l',
    { desc = 'Move to right window', silent = true }
  )

  -- Scrolling in terminal mode
  if scroll.enable then
    vim.keymap.set('t', scroll.page_up, '<C-\\><C-n><C-b>i', { desc = 'Page up', silent = true })
    vim.keymap.set(
      't',
      scroll.page_down,
      '<C-\\><C-n><C-f>i',
      { desc = 'Page down', silent = true }
    )
  end
end

-- Setup which-key integration
-- @param config table The plugin configuration
function M.setup_whichkey_integration(config)
  -- Defer to avoid errors if which-key not installed
  vim.defer_fn(function()
    local ok, wk = pcall(require, 'which-key')
    if not ok then
      return
    end

    local mappings = {
      c = {
        name = 'Codex',
        c = { 'Continue' },
        r = { 'Resume' },
        v = { 'Verbose' },
        x = { 'Exec' },
        b = { 'Send buffer' },
        s = { 'Send selection' },
      },
    }

    -- Register with which-key v2 or v3 API
    local register_ok = pcall(function()
      wk.register(mappings, { prefix = '<leader>' })
    end)

    -- If v2 API fails, try v3 API
    if not register_ok then
      pcall(function()
        wk.add({
          { '<leader>c', group = 'Codex' },
          { '<leader>cc', desc = 'Continue' },
          { '<leader>cr', desc = 'Resume' },
          { '<leader>cv', desc = 'Verbose' },
          { '<leader>cx', desc = 'Exec' },
          { '<leader>cb', desc = 'Send buffer' },
          { '<leader>cs', desc = 'Send selection' },
        })
      end)
    end
  end, 100)
end

return M
