-- Example configuration for codex.nvim
-- Copy and modify this to your init.lua or init.vim

-- Minimal configuration (uses all defaults)
require('codex').setup()

-- Full configuration with all options
require('codex').setup({
  -- Terminal window configuration
  window = {
    split_ratio = 0.3, -- Size of split (0.0-1.0)
    position = 'botright', -- 'botright', 'topleft', 'vertical', 'float'
    enter_insert = true, -- Enter insert mode when opening
    start_in_normal_mode = false, -- Override enter_insert
    hide_numbers = true, -- Hide line numbers
    hide_signcolumn = true, -- Hide sign column

    -- Floating window options (when position = 'float')
    float = {
      width = '80%', -- Width (number or percentage)
      height = '80%', -- Height
      row = 'center', -- Row position
      col = 'center', -- Column position
      border = 'rounded', -- Border style: 'none', 'single', 'double', 'rounded', 'solid'
      relative = 'editor', -- Relative to 'editor' or 'cursor'
    },
  },

  -- File refresh configuration
  refresh = {
    enable = true, -- Enable file monitoring
    updatetime = 100, -- Vim updatetime while active (ms)
    timer_interval = 1000, -- Polling interval (ms)
    show_notifications = false, -- Notify on file changes
  },

  -- Git integration
  git = {
    use_git_root = true, -- Use git root as cwd
    multi_instance = true, -- One instance per repo
  },

  -- Shell commands
  shell = {
    separator = ' && ', -- Command separator
    pushd_cmd = 'pushd', -- Directory change command
    popd_cmd = 'popd', -- Directory restore command
  },

  -- Base command
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
      flags = 'exec',
    },
  },

  -- Context management
  context = {
    method = 'stdin', -- 'stdin', 'clipboard', 'file'
    auto_send_on_open = false, -- Auto-send buffer on open
    include_filepath = true, -- Include filepath in context
    max_lines = 10000, -- Max lines to send
  },

  -- MCP integration
  mcp = {
    enable = false, -- Enable MCP
    config_path = nil, -- Custom config path (default: ~/.codex/config.toml)
    show_status = true, -- Show MCP status
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
})

-- Custom keymaps (optional)
-- Send buffer and immediately open Codex
vim.keymap.set('n', '<leader>ca', function()
  require('codex').send_buffer()
  require('codex').toggle()
end, { desc = 'Send buffer and open Codex' })

-- Quick exec for common tasks
vim.keymap.set('n', '<leader>cf', function()
  require('codex').exec('Fix all errors and warnings in this file')
end, { desc = 'Codex: Fix errors' })

vim.keymap.set('n', '<leader>cd', function()
  require('codex').exec('Add documentation to all functions in this file')
end, { desc = 'Codex: Add documentation' })

vim.keymap.set('n', '<leader>ct', function()
  require('codex').exec('Write tests for this file')
end, { desc = 'Codex: Write tests' })
