# Codex.nvim Implementation Guide

> **Complete specification and implementation guide for creating a Neovim plugin that integrates with OpenAI's Codex CLI**

This document provides a comprehensive, step-by-step guide for implementing codex.nvim, a Neovim plugin that mirrors the architecture of claude-code.nvim but works with OpenAI's Codex CLI.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Design](#architecture-design)
3. [Project Structure](#project-structure)
4. [Module Specifications](#module-specifications)
5. [Implementation Phases](#implementation-phases)
6. [API Reference](#api-reference)
7. [Configuration Reference](#configuration-reference)
8. [Testing Strategy](#testing-strategy)
9. [Documentation Requirements](#documentation-requirements)

---

## Project Overview

### Goals
- Create a seamless Neovim integration for OpenAI's Codex CLI
- Provide multi-instance support (one Codex per git repository)
- Implement automatic file change detection and reloading
- Add enhanced context management (buffer/file sending)
- Support both interactive and exec modes
- Enable MCP (Model Context Protocol) server integration

### Key Features
1. **Terminal Management**: Toggle Codex terminal with configurable windows (split/float)
2. **Multi-Instance**: Separate Codex instances per git repository
3. **Git Integration**: Automatically use git root as working directory
4. **File Monitoring**: Auto-reload files modified by Codex
5. **Context Sending**: Send buffers, selections, files to Codex
6. **Exec Mode**: Non-interactive command execution
7. **MCP Support**: Integration with Model Context Protocol servers
8. **Keyboard Navigation**: Full keymap support with which-key integration

### Technology Stack
- **Language**: Lua (Neovim's embedded language)
- **CLI Tool**: Codex CLI (`@openai/codex` from npm or Homebrew)
- **Target**: Neovim 0.8.0+
- **Testing**: Custom Lua test runner (port from claude-code.nvim)

---

## Architecture Design

### Core Principles

1. **Modular Design**: Clear separation of concerns with single-responsibility modules
2. **Configuration-Driven**: All behavior configurable without code changes
3. **State Management**: Single global module table tracking all instances
4. **Terminal Wrapper**: Direct terminal buffer interaction (no custom protocol)
5. **Lazy Initialization**: Setup happens in `setup()` function called by user
6. **Validation First**: Comprehensive config validation with fallback to defaults

### State Management Pattern

```lua
-- Global plugin state structure
M.codex = {
  instances = {
    -- Key: instance_id (git root path or 'global')
    -- Value: buffer number
    ['/path/to/project1'] = 42,
    ['/path/to/project2'] = 57,
  },
  current_instance = '/path/to/project1',  -- Currently active instance
  saved_updatetime = 1000,  -- Original updatetime value
}
```

### Module Responsibilities

| Module | Responsibility | Dependencies |
|--------|---------------|--------------|
| `init.lua` | Entry point, public API, setup orchestration | All modules |
| `config.lua` | Configuration parsing, validation, defaults | None |
| `terminal.lua` | Terminal buffer/window management, process lifecycle | config, git |
| `git.lua` | Git repository detection | None |
| `file_refresh.lua` | File change detection and reloading | terminal |
| `commands.lua` | Neovim command registration | terminal |
| `keymaps.lua` | Keyboard binding management | terminal |
| `context.lua` | **NEW** - Buffer/file context sending | terminal, git |
| `mcp.lua` | **NEW** - MCP server integration | config |
| `version.lua` | Version information | None |

### Data Flow

```
User Action (keymap/command)
    ↓
commands.lua → terminal.lua
    ↓
git.lua (get instance_id)
    ↓
terminal.lua (create/toggle/manage terminal)
    ↓
file_refresh.lua (monitor changes)
    ↓
Auto-reload buffers when Codex modifies files
```

---

## Project Structure

```
codex.nvim/
├── lua/
│   └── codex/
│       ├── init.lua              # Entry point & public API
│       ├── config.lua            # Configuration management
│       ├── terminal.lua          # Terminal/process management
│       ├── git.lua               # Git integration
│       ├── file_refresh.lua      # File change detection
│       ├── commands.lua          # Command registration
│       ├── keymaps.lua           # Keymap handling
│       ├── context.lua           # NEW: Context sending utilities
│       ├── mcp.lua               # NEW: MCP integration
│       └── version.lua           # Version info
├── tests/
│   ├── run_tests.lua             # Test runner
│   ├── test_config.lua           # Config tests
│   ├── test_terminal.lua         # Terminal tests
│   ├── test_git.lua              # Git tests
│   ├── test_context.lua          # Context tests
│   └── test_mcp.lua              # MCP tests
├── doc/
│   └── codex.txt                 # Vim help documentation
├── after/
│   └── plugin/
│       └── codex.lua             # Auto-initialization (optional)
├── README.md                     # User documentation
├── IMPLEMENTATION.md             # This file
├── CODEX.md                      # Project instructions (for AI assistants)
├── LICENSE                       # Apache 2.0 (to match Codex CLI)
└── .gitignore                    # Standard Lua/Neovim ignores
```

---

## Module Specifications

### 1. init.lua - Entry Point & Public API

**Purpose**: Main entry point exposing the plugin's public API and orchestrating initialization.

**State Management**:
```lua
local M = {}

-- Plugin state (global singleton)
M.codex = {
  instances = {},           -- { [instance_id] = buffer_number }
  current_instance = nil,   -- Current instance identifier
  saved_updatetime = nil,   -- Stored original updatetime
}

M.config = nil  -- Initialized in setup()
```

**Public API**:
```lua
-- Setup function (called by user in init.lua/init.vim)
function M.setup(user_config)
  -- 1. Parse and validate configuration
  M.config = config.parse_config(user_config or {})

  -- 2. Enable autoread for file monitoring
  vim.o.autoread = true

  -- 3. Setup file refresh monitoring
  file_refresh.setup(M, M.config)

  -- 4. Register commands (:Codex, :CodexExec, etc.)
  commands.register_commands(M)

  -- 5. Register keymaps
  keymaps.register_keymaps(M, M.config)

  -- 6. Setup MCP if configured
  if M.config.mcp.enable then
    mcp.setup(M.config)
  end
end

-- Toggle Codex terminal (main command)
function M.toggle()
  terminal.toggle(M.codex, M.config)
end

-- Toggle with command variant (--continue, --exec, etc.)
function M.toggle_with_variant(variant_name)
  terminal.toggle_with_variant(M.codex, M.config, variant_name)
end

-- Execute non-interactive command
function M.exec(prompt)
  terminal.exec(M.codex, M.config, prompt)
end

-- Send context to Codex
function M.send_buffer()
  context.send_buffer(M.codex, M.config)
end

function M.send_selection()
  context.send_selection(M.codex, M.config)
end

function M.send_file(filepath)
  context.send_file(M.codex, M.config, filepath)
end

-- Force terminal into insert mode
function M.force_insert_mode()
  terminal.force_insert_mode(M.codex, M.config)
end

-- Get plugin version
function M.get_version()
  return version.get_version()
end

return M
```

**Implementation Notes**:
- Keep state management centralized in `M.codex`
- All public functions should validate state before operations
- Error handling: graceful fallbacks with user notifications
- Module should be stateless except for `M.codex` and `M.config`

---

### 2. config.lua - Configuration Management

**Purpose**: Define defaults, parse user config, validate all settings.

**Default Configuration**:
```lua
M.default_config = {
  -- Terminal window configuration
  window = {
    split_ratio = 0.3,                    -- Size of split (0.0-1.0)
    position = 'botright',                -- 'botright', 'topleft', 'vertical', 'float'
    enter_insert = true,                  -- Enter insert mode when opening
    start_in_normal_mode = false,         -- Start in normal mode instead
    hide_numbers = true,                  -- Hide line numbers in terminal
    hide_signcolumn = true,               -- Hide sign column

    -- Floating window specific options
    float = {
      width = '80%',                      -- Width (number or percentage)
      height = '80%',                     -- Height (number or percentage)
      row = 'center',                     -- Row position ('center' or number/percentage)
      col = 'center',                     -- Col position ('center' or number/percentage)
      border = 'rounded',                 -- Border style
      relative = 'editor',                -- Relative to 'editor' or 'cursor'
    },
  },

  -- File refresh configuration
  refresh = {
    enable = true,                        -- Enable file monitoring
    updatetime = 100,                     -- Vim updatetime while terminal active
    timer_interval = 1000,                -- Polling interval (ms)
    show_notifications = false,           -- Notify on file changes
  },

  -- Git integration
  git = {
    use_git_root = true,                  -- Change to git root when opening
    multi_instance = true,                -- One instance per git root
  },

  -- Shell command configuration
  shell = {
    separator = ' && ',                   -- Command separator
    pushd_cmd = 'pushd',                  -- Directory change command
    popd_cmd = 'popd',                    -- Directory restore command
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
      flags = 'exec',                     -- Subcommand, not flag
    },
  },

  -- Context management (NEW)
  context = {
    method = 'stdin',                     -- 'stdin', 'clipboard', 'file'
    auto_send_on_open = false,            -- Auto-send current buffer on open
    include_filepath = true,              -- Include file path in context
    max_lines = 10000,                    -- Max lines to send
  },

  -- MCP integration (NEW)
  mcp = {
    enable = false,                       -- Enable MCP integration
    config_path = nil,                    -- Path to MCP config (default: ~/.codex/config.toml)
    show_status = true,                   -- Show MCP status in terminal
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
```

**Validation Functions**:
```lua
-- Validate entire configuration
function validate_config(config)
  local validators = {
    validate_window_config,
    validate_float_config,
    validate_refresh_config,
    validate_git_config,
    validate_shell_config,
    validate_command_config,
    validate_context_config,     -- NEW
    validate_mcp_config,          -- NEW
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

-- Example: Validate window configuration
function validate_window_config(config)
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

-- NEW: Validate context configuration
function validate_context_config(config)
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

-- NEW: Validate MCP configuration
function validate_mcp_config(config)
  if type(config.mcp) ~= 'table' then
    return false, 'mcp must be a table'
  end

  if config.mcp.config_path and type(config.mcp.config_path) ~= 'string' then
    return false, 'mcp.config_path must be a string or nil'
  end

  return true
end
```

**Parse Function**:
```lua
function M.parse_config(user_config)
  -- Merge user config with defaults (deep merge)
  local config = vim.tbl_deep_extend('force', {}, M.default_config, user_config)

  -- Validate
  local valid, err = validate_config(config)
  if not valid then
    vim.notify('Codex.nvim: Invalid configuration - ' .. err, vim.log.levels.ERROR)
    return vim.deepcopy(M.default_config)  -- Fallback to safe defaults
  end

  return config
end
```

**Implementation Notes**:
- Add validation for every config field
- Provide helpful error messages
- Always fallback to working defaults on error
- Support backward compatibility if config structure changes

---

### 3. terminal.lua - Terminal & Process Management

**Purpose**: Manage terminal buffers, windows, and Codex processes.

**Key Functions**:

```lua
local M = {}

-- Toggle Codex terminal
function M.toggle(codex_state, config)
  local instance_id = get_instance_id(config)
  local bufnr = codex_state.instances[instance_id]

  if bufnr and is_valid_terminal_buffer(bufnr) then
    handle_existing_instance(codex_state, config, instance_id, bufnr)
  else
    create_new_instance(codex_state, config, instance_id)
  end
end

-- Toggle with command variant
function M.toggle_with_variant(codex_state, config, variant_name)
  local variant = config.command_variants[variant_name]
  if not variant or not variant.enabled then
    vim.notify('Codex.nvim: Variant "' .. variant_name .. '" not enabled', vim.log.levels.WARN)
    return
  end

  -- Temporarily modify config to include variant
  local modified_config = vim.deepcopy(config)
  modified_config._active_variant = variant

  M.toggle(codex_state, modified_config)
end

-- Execute non-interactive command (exec mode)
function M.exec(codex_state, config, prompt)
  if not prompt or prompt == '' then
    prompt = vim.fn.input('Codex exec: ')
    if not prompt or prompt == '' then
      return
    end
  end

  -- Build exec command
  local cmd = build_exec_command(config, prompt)

  -- Create temporary buffer for output
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

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
    end
  })
end

-- Get instance identifier
function get_instance_id(config)
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
function is_valid_terminal_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
  if buftype ~= 'terminal' then
    return false
  end

  -- Check if terminal job is still running
  local terminal_job_id = vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
  if not terminal_job_id then
    return false
  end

  local job_status = vim.fn.jobwait({ terminal_job_id }, 0)[1]
  return job_status == -1  -- -1 means still running
end

-- Handle existing instance (toggle visibility)
function handle_existing_instance(codex_state, config, instance_id, bufnr)
  local win_id = find_window_for_buffer(bufnr)

  if win_id then
    -- Buffer is visible, close it
    vim.api.nvim_win_close(win_id, false)
  else
    -- Buffer is hidden, show it
    open_terminal_window(bufnr, config)
    codex_state.current_instance = instance_id

    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd('startinsert')
    end
  end
end

-- Create new Codex instance
function create_new_instance(codex_state, config, instance_id)
  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'terminal')
  vim.api.nvim_buf_set_option(bufnr, 'buflisted', false)

  -- Set buffer name
  local safe_instance_id = instance_id:gsub('[/\\:]', '-')
  vim.api.nvim_buf_set_name(bufnr, 'codex-' .. safe_instance_id)

  -- Open window
  open_terminal_window(bufnr, config)

  -- Build command
  local cmd = build_command_with_git_root(config, instance_id)

  -- Start terminal
  local job_id = vim.fn.termopen(cmd)

  if job_id == 0 or job_id == -1 then
    vim.notify('Codex.nvim: Failed to start Codex', vim.log.levels.ERROR)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return
  end

  -- Store buffer number
  codex_state.instances[instance_id] = bufnr
  codex_state.current_instance = instance_id

  -- Configure window
  local win_id = vim.api.nvim_get_current_win()
  configure_window_options(win_id, config)

  -- Enter insert mode if configured
  if config.window.enter_insert and not config.window.start_in_normal_mode then
    vim.cmd('startinsert')
  end
end

-- Build Codex command with git root
function build_command_with_git_root(config, instance_id)
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
function build_exec_command(config, prompt)
  local cmd_parts = { config.command, 'exec', vim.fn.shellescape(prompt) }
  return table.concat(cmd_parts, ' ')
end

-- Open terminal window (split or float)
function open_terminal_window(bufnr, config)
  if config.window.position == 'float' then
    create_float(bufnr, config)
  else
    create_split(bufnr, config)
  end
end

-- Create floating window
function create_float(bufnr, config)
  local float_config = config.window.float

  -- Get editor dimensions
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  -- Calculate dimensions
  local width = calculate_dimension(float_config.width, editor_width)
  local height = calculate_dimension(float_config.height, editor_height)

  -- Calculate position
  local row = calculate_position(float_config.row, height, editor_height)
  local col = calculate_position(float_config.col, width, editor_width)

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
function create_split(bufnr, config)
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

-- Configure window options
function configure_window_options(win_id, config)
  if config.window.hide_numbers then
    vim.api.nvim_set_option_value('number', false, { win = win_id })
    vim.api.nvim_set_option_value('relativenumber', false, { win = win_id })
  end

  if config.window.hide_signcolumn then
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = win_id })
  end
end

-- Helper: Calculate dimension from percentage or absolute
function calculate_dimension(value, max_value)
  if type(value) == 'string' and value:match('%%$') then
    local percent = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_value * percent / 100)
  else
    return value
  end
end

-- Helper: Calculate position
function calculate_position(value, size, max_size)
  if value == 'center' then
    return math.floor((max_size - size) / 2)
  elseif type(value) == 'string' and value:match('%%$') then
    local percent = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_size * percent / 100)
  else
    return value
  end
end

-- Helper: Find window displaying buffer
function find_window_for_buffer(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
  return nil
end

-- Force insert mode in terminal
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
```

**Implementation Notes**:
- Validate all buffer/window operations
- Handle edge cases (terminal dies, buffer deleted, etc.)
- Support both split and float windows
- Track multiple instances reliably

---

### 4. git.lua - Git Integration

**Purpose**: Detect git repositories and get root path.

**Implementation** (port directly from claude-code.nvim):
```lua
local M = {}

-- Get git root directory for current buffer
function M.get_git_root()
  local current_file = vim.fn.expand('%:p')
  local current_dir

  if current_file == '' then
    current_dir = vim.fn.getcwd()
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Check if we're in a git repository
  local cmd = string.format("cd %s && git rev-parse --is-inside-work-tree 2>/dev/null",
                           vim.fn.shellescape(current_dir))
  local handle = io.popen(cmd)
  local result = handle:read('*a')
  handle:close()

  if result:match('true') then
    -- Get git root
    cmd = string.format("cd %s && git rev-parse --show-toplevel",
                        vim.fn.shellescape(current_dir))
    handle = io.popen(cmd)
    local git_root = handle:read('*a')
    handle:close()

    return git_root:gsub('[\n\r%s]*$', '')  -- Trim whitespace
  end

  return nil
end

return M
```

**Implementation Notes**:
- No changes needed from claude-code.nvim
- Git integration is tool-agnostic
- Handle cases where git is not installed

---

### 5. file_refresh.lua - File Change Detection

**Purpose**: Monitor and reload files modified by Codex.

**Implementation** (port from claude-code.nvim with minor adjustments):
```lua
local M = {}

local refresh_timer = nil

function M.setup(plugin_state, config)
  if not config.refresh.enable then
    return
  end

  -- Setup autocommands for file change detection
  setup_file_change_detection(config)

  -- Setup periodic refresh timer
  setup_refresh_timer(plugin_state, config)

  -- Setup updatetime management
  setup_updatetime_management(plugin_state, config)
end

-- Setup file change detection autocommands
function setup_file_change_detection(config)
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
function setup_refresh_timer(plugin_state, config)
  refresh_timer = vim.loop.new_timer()

  refresh_timer:start(0, config.refresh.timer_interval, vim.schedule_wrap(function()
    -- Only refresh if Codex terminal is visible
    if is_codex_visible(plugin_state) then
      vim.cmd('silent! checktime')
    end
  end))
end

-- Check if any Codex terminal is visible
function is_codex_visible(plugin_state)
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
function setup_updatetime_management(plugin_state, config)
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
        if not is_codex_visible(plugin_state) and plugin_state.codex.saved_updatetime then
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
```

**Implementation Notes**:
- Reuse claude-code architecture exactly
- Change group names from `ClaudeFileRefresh` to `CodexFileRefresh`
- No functional changes needed

---

### 6. commands.lua - Command Registration

**Purpose**: Register Neovim user commands.

**Implementation**:
```lua
local M = {}

function M.register_commands(plugin)
  -- Main toggle command
  vim.api.nvim_create_user_command('Codex', function()
    plugin.toggle()
  end, {
    desc = 'Toggle Codex terminal',
  })

  -- Exec mode command
  vim.api.nvim_create_user_command('CodexExec', function(opts)
    plugin.exec(opts.args)
  end, {
    nargs = '?',
    desc = 'Execute Codex in non-interactive mode',
  })

  -- Variant commands
  if plugin.config.command_variants.continue.enabled then
    vim.api.nvim_create_user_command('CodexContinue', function()
      plugin.toggle_with_variant('continue')
    end, {
      desc = 'Toggle Codex with --continue',
    })
  end

  if plugin.config.command_variants.resume.enabled then
    vim.api.nvim_create_user_command('CodexResume', function()
      plugin.toggle_with_variant('resume')
    end, {
      desc = 'Toggle Codex with --resume',
    })
  end

  if plugin.config.command_variants.verbose.enabled then
    vim.api.nvim_create_user_command('CodexVerbose', function()
      plugin.toggle_with_variant('verbose')
    end, {
      desc = 'Toggle Codex with --verbose',
    })
  end

  -- Context commands
  vim.api.nvim_create_user_command('CodexSendBuffer', function()
    plugin.send_buffer()
  end, {
    desc = 'Send current buffer to Codex',
  })

  vim.api.nvim_create_user_command('CodexSendSelection', function()
    plugin.send_selection()
  end, {
    range = true,
    desc = 'Send visual selection to Codex',
  })

  vim.api.nvim_create_user_command('CodexSendFile', function(opts)
    plugin.send_file(opts.args)
  end, {
    nargs = 1,
    complete = 'file',
    desc = 'Send file to Codex',
  })

  -- Version command
  vim.api.nvim_create_user_command('CodexVersion', function()
    local version = plugin.get_version()
    vim.notify('Codex.nvim version: ' .. version, vim.log.levels.INFO)
  end, {
    desc = 'Show Codex.nvim version',
  })
end

return M
```

**Implementation Notes**:
- Use `vim.api.nvim_create_user_command` (Neovim 0.7+)
- Add descriptions for `:help` documentation
- Support command completion where appropriate
- Conditionally register based on config

---

### 7. keymaps.lua - Keymap Management

**Purpose**: Register and manage keyboard bindings.

**Implementation**:
```lua
local M = {}

function M.register_keymaps(plugin, config)
  setup_toggle_keymaps(plugin, config)
  setup_variant_keymaps(plugin, config)
  setup_context_keymaps(plugin, config)
  setup_terminal_navigation(plugin, config)
  setup_whichkey_integration(config)
end

-- Setup main toggle keymaps
function setup_toggle_keymaps(plugin, config)
  local toggle_config = config.keymaps.toggle

  if toggle_config.normal then
    vim.keymap.set('n', toggle_config.normal, function()
      plugin.toggle()
    end, { desc = 'Toggle Codex' })
  end

  if toggle_config.terminal then
    vim.keymap.set('t', toggle_config.terminal, function()
      plugin.toggle()
    end, { desc = 'Toggle Codex' })
  end
end

-- Setup variant keymaps
function setup_variant_keymaps(plugin, config)
  local variants = config.keymaps.toggle.variants

  for variant_name, keymap in pairs(variants) do
    if keymap and config.command_variants[variant_name].enabled then
      vim.keymap.set('n', keymap, function()
        plugin.toggle_with_variant(variant_name)
      end, { desc = 'Codex ' .. variant_name })
    end
  end
end

-- Setup context sending keymaps
function setup_context_keymaps(plugin, config)
  local context_config = config.keymaps.context

  if context_config.send_buffer then
    vim.keymap.set('n', context_config.send_buffer, function()
      plugin.send_buffer()
    end, { desc = 'Send buffer to Codex' })
  end

  if context_config.send_selection then
    vim.keymap.set('v', context_config.send_selection, function()
      plugin.send_selection()
    end, { desc = 'Send selection to Codex' })
  end
end

-- Setup terminal window navigation
function setup_terminal_navigation(plugin, config)
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
  vim.keymap.set('t', nav.left, '<C-\\><C-n><C-w>h', { desc = 'Move to left window' })
  vim.keymap.set('t', nav.down, '<C-\\><C-n><C-w>j', { desc = 'Move to below window' })
  vim.keymap.set('t', nav.up, '<C-\\><C-n><C-w>k', { desc = 'Move to above window' })
  vim.keymap.set('t', nav.right, '<C-\\><C-n><C-w>l', { desc = 'Move to right window' })

  -- Scrolling in terminal mode
  if scroll.enable then
    vim.keymap.set('t', scroll.page_up, '<C-\\><C-n><C-b>i', { desc = 'Page up' })
    vim.keymap.set('t', scroll.page_down, '<C-\\><C-n><C-f>i', { desc = 'Page down' })
  end
end

-- Setup which-key integration
function setup_whichkey_integration(config)
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

    wk.register(mappings, { prefix = '<leader>' })
  end, 100)
end

return M
```

**Implementation Notes**:
- All keymaps should be configurable
- Support disabling with `false`
- Add descriptions for which-key
- Handle terminal mode keymaps specially

---

### 8. context.lua - Context Sending (NEW)

**Purpose**: Send buffer/file content to Codex terminal.

**Implementation**:
```lua
local M = {}

-- Send current buffer to Codex
function M.send_buffer(codex_state, config)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Check max_lines limit
  if #lines > config.context.max_lines then
    vim.notify(
      string.format('Buffer has %d lines, exceeds max_lines (%d)', #lines, config.context.max_lines),
      vim.log.levels.WARN
    )
    return
  end

  -- Build context
  local context = build_context(lines, filepath, config)

  -- Send to Codex
  send_to_codex(codex_state, config, context)
end

-- Send visual selection to Codex
function M.send_selection(codex_state, config)
  -- Get visual selection
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local bufnr = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Build context
  local context = build_context(lines, filepath, config, start_line, end_line)

  -- Send to Codex
  send_to_codex(codex_state, config, context)
end

-- Send specific file to Codex
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
  local context = build_context(lines, filepath, config)

  -- Send to Codex
  send_to_codex(codex_state, config, context)
end

-- Build context string
function build_context(lines, filepath, config, start_line, end_line)
  local parts = {}

  if config.context.include_filepath and filepath ~= '' then
    if start_line and end_line then
      table.insert(parts, string.format('File: %s (lines %d-%d)', filepath, start_line, end_line))
    else
      table.insert(parts, 'File: ' .. filepath)
    end
    table.insert(parts, '')
  end

  -- Add code fence for markdown formatting
  local ext = vim.fn.fnamemodify(filepath, ':e')
  table.insert(parts, '```' .. ext)

  for _, line in ipairs(lines) do
    table.insert(parts, line)
  end

  table.insert(parts, '```')

  return table.concat(parts, '\n')
end

-- Send context to Codex terminal
function send_to_codex(codex_state, config, context)
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
    send_via_stdin(bufnr, context)
  elseif method == 'clipboard' then
    send_via_clipboard(context)
  elseif method == 'file' then
    send_via_file(bufnr, context)
  else
    vim.notify('Unknown context method: ' .. method, vim.log.levels.ERROR)
  end
end

-- Send via stdin (paste into terminal)
function send_via_stdin(bufnr, context)
  -- Get terminal job ID
  local job_id = vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
  if not job_id then
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
function send_via_clipboard(context)
  vim.fn.setreg('+', context)
  vim.notify('Context copied to clipboard. Paste into Codex terminal.', vim.log.levels.INFO)
end

-- Send via temporary file
function send_via_file(bufnr, context)
  -- Create temp file
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.split(context, '\n', { plain = true }), tmpfile)

  -- Get terminal job ID
  local job_id = vim.api.nvim_buf_get_var(bufnr, 'terminal_job_id')
  if not job_id then
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
```

**Implementation Notes**:
- Support multiple sending methods (stdin, clipboard, file)
- Add proper formatting with code fences
- Include filepath in context
- Respect max_lines limit
- Provide user feedback

---

### 9. mcp.lua - MCP Integration (NEW)

**Purpose**: Integrate with Model Context Protocol servers.

**Implementation**:
```lua
local M = {}

-- Setup MCP integration
function M.setup(config)
  if not config.mcp.enable then
    return
  end

  -- Read MCP config
  local mcp_config_path = config.mcp.config_path or get_default_config_path()
  local mcp_servers = parse_mcp_config(mcp_config_path)

  if not mcp_servers or #mcp_servers == 0 then
    vim.notify('No MCP servers configured', vim.log.levels.INFO)
    return
  end

  -- Register commands
  register_mcp_commands(mcp_servers)

  -- Show status if configured
  if config.mcp.show_status then
    vim.notify(string.format('MCP: %d servers available', #mcp_servers), vim.log.levels.INFO)
  end
end

-- Get default MCP config path
function get_default_config_path()
  local home = vim.fn.expand('~')
  return home .. '/.codex/config.toml'
end

-- Parse MCP config file
function parse_mcp_config(config_path)
  if vim.fn.filereadable(config_path) == 0 then
    return {}
  end

  -- Read and parse TOML (simple parsing, may need toml library)
  local lines = vim.fn.readfile(config_path)
  local servers = {}
  local current_server = nil

  for _, line in ipairs(lines) do
    -- Match server sections: [mcp.servers.servername]
    local server_name = line:match('%[mcp%.servers%.([^%]]+)%]')
    if server_name then
      current_server = { name = server_name, enabled = true }
      table.insert(servers, current_server)
    end
  end

  return servers
end

-- Register MCP-related commands
function register_mcp_commands(servers)
  -- List MCP servers
  vim.api.nvim_create_user_command('CodexMcpList', function()
    local lines = { 'MCP Servers:' }
    for _, server in ipairs(servers) do
      table.insert(lines, string.format('  - %s', server.name))
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, {
    desc = 'List MCP servers',
  })
end

return M
```

**Implementation Notes**:
- Parse TOML config (may need external library or simple regex)
- Provide commands to list/manage MCP servers
- This is a basic implementation; can be enhanced later
- MCP integration is primarily handled by Codex CLI itself

---

### 10. version.lua - Version Information

**Purpose**: Provide version information.

**Implementation**:
```lua
local M = {}

M.VERSION = '1.0.0'

function M.get_version()
  return M.VERSION
end

return M
```

**Implementation Notes**:
- Simple module
- Update VERSION on each release
- Could add git commit hash for dev builds

---

## Implementation Phases

### Phase 1: Project Setup (Week 1)
1. Create repository structure
2. Initialize git repo
3. Add LICENSE (Apache 2.0)
4. Create README skeleton
5. Add .gitignore for Lua/Neovim

### Phase 2: Core Configuration (Week 1)
1. Implement `config.lua` with all defaults
2. Write validation functions
3. Test config parsing and merging
4. Add unit tests for validation

### Phase 3: Terminal Management (Week 2)
1. Implement `terminal.lua` core functions
2. Add split window support
3. Add floating window support
4. Implement instance management
5. Test multi-instance behavior

### Phase 4: Git Integration & Commands (Week 2)
1. Port `git.lua` from claude-code.nvim
2. Implement `commands.lua`
3. Test command registration
4. Verify git root detection

### Phase 5: Keymaps & Navigation (Week 3)
1. Implement `keymaps.lua`
2. Add terminal navigation
3. Test all keybindings
4. Add which-key integration

### Phase 6: File Monitoring (Week 3)
1. Port `file_refresh.lua`
2. Test file change detection
3. Verify updatetime management
4. Test notification system

### Phase 7: Context Management (Week 4)
1. Implement `context.lua`
2. Add buffer sending
3. Add selection sending
4. Add file sending
5. Test all sending methods

### Phase 8: Exec Mode (Week 4)
1. Add exec mode to terminal.lua
2. Implement output capture
3. Add exec command
4. Test non-interactive execution

### Phase 9: MCP Integration (Week 5)
1. Implement `mcp.lua`
2. Add TOML parsing
3. Add MCP commands
4. Test with real MCP servers

### Phase 10: Testing & Documentation (Week 5-6)
1. Write comprehensive test suite
2. Create Vim help documentation
3. Write detailed README
4. Add examples and screenshots
5. Create CONTRIBUTING guide

---

## API Reference

### Public Functions

#### `setup(config)`
Initialize the plugin with user configuration.

**Parameters**:
- `config` (table, optional): User configuration (merged with defaults)

**Example**:
```lua
require('codex').setup({
  window = {
    position = 'float',
    split_ratio = 0.4,
  },
  git = {
    multi_instance = true,
  },
  keymaps = {
    toggle = {
      normal = '<C-\\>',
    },
  },
})
```

#### `toggle()`
Toggle the Codex terminal.

**Example**:
```lua
vim.keymap.set('n', '<leader>ct', require('codex').toggle)
```

#### `toggle_with_variant(variant_name)`
Toggle Codex with a specific variant.

**Parameters**:
- `variant_name` (string): Name of variant ('continue', 'resume', 'verbose', 'exec')

**Example**:
```lua
require('codex').toggle_with_variant('continue')
```

#### `exec(prompt)`
Execute Codex in non-interactive mode.

**Parameters**:
- `prompt` (string, optional): Prompt for exec mode (will prompt user if not provided)

**Example**:
```lua
require('codex').exec('Fix all TypeScript errors in this file')
```

#### `send_buffer()`
Send current buffer content to Codex.

**Example**:
```lua
vim.keymap.set('n', '<leader>cb', require('codex').send_buffer)
```

#### `send_selection()`
Send visual selection to Codex.

**Example**:
```lua
vim.keymap.set('v', '<leader>cs', require('codex').send_selection)
```

#### `send_file(filepath)`
Send specific file to Codex.

**Parameters**:
- `filepath` (string): Path to file (supports vim wildcards like `%`, `~`)

**Example**:
```lua
require('codex').send_file('~/project/main.lua')
```

---

## Configuration Reference

### Complete Configuration Example

```lua
require('codex').setup({
  -- Window configuration
  window = {
    split_ratio = 0.3,              -- Size when using split (0.0-1.0)
    position = 'botright',          -- 'botright', 'topleft', 'vertical', 'float'
    enter_insert = true,            -- Auto-enter insert mode
    start_in_normal_mode = false,   -- Override enter_insert
    hide_numbers = true,            -- Hide line numbers
    hide_signcolumn = true,         -- Hide sign column

    -- Floating window settings (when position = 'float')
    float = {
      width = '80%',                -- Width (number or '80%')
      height = '80%',               -- Height
      row = 'center',               -- Row ('center', number, or '10%')
      col = 'center',               -- Column
      border = 'rounded',           -- 'none', 'single', 'double', 'rounded', 'solid'
      relative = 'editor',          -- 'editor' or 'cursor'
    },
  },

  -- File refresh settings
  refresh = {
    enable = true,                  -- Enable auto-reload
    updatetime = 100,               -- Vim updatetime while active (ms)
    timer_interval = 1000,          -- Polling interval (ms)
    show_notifications = false,     -- Show reload notifications
  },

  -- Git integration
  git = {
    use_git_root = true,            -- Use git root as cwd
    multi_instance = true,          -- One instance per repo
  },

  -- Shell commands
  shell = {
    separator = ' && ',             -- Command separator
    pushd_cmd = 'pushd',            -- Directory push command
    popd_cmd = 'popd',              -- Directory pop command
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
    method = 'stdin',               -- 'stdin', 'clipboard', 'file'
    auto_send_on_open = false,      -- Auto-send buffer on open
    include_filepath = true,        -- Include filepath in context
    max_lines = 10000,              -- Max lines to send
  },

  -- MCP integration
  mcp = {
    enable = false,                 -- Enable MCP
    config_path = nil,              -- Custom config path
    show_status = true,             -- Show MCP status
  },

  -- Keyboard mappings
  keymaps = {
    toggle = {
      normal = '<C-,>',             -- Toggle in normal mode
      terminal = '<C-,>',           -- Toggle in terminal mode
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
```

---

## Testing Strategy

### Test Structure

```
tests/
├── run_tests.lua          # Main test runner
├── test_helpers.lua       # Shared test utilities
├── test_config.lua        # Configuration tests
├── test_terminal.lua      # Terminal management tests
├── test_git.lua           # Git integration tests
├── test_context.lua       # Context sending tests
└── test_mcp.lua           # MCP integration tests
```

### Test Categories

1. **Configuration Tests** (`test_config.lua`):
   - Default config structure
   - Config parsing and merging
   - Validation for each section
   - Error handling and fallbacks

2. **Terminal Tests** (`test_terminal.lua`):
   - Instance creation and management
   - Window creation (split and float)
   - Buffer validation
   - Multi-instance behavior
   - Toggle functionality

3. **Git Tests** (`test_git.lua`):
   - Git root detection
   - Non-git directory handling
   - Instance ID generation

4. **Context Tests** (`test_context.lua`):
   - Buffer sending
   - Selection sending
   - File sending
   - Context formatting
   - Max lines limit

5. **MCP Tests** (`test_mcp.lua`):
   - Config parsing
   - Server listing
   - Command registration

### Running Tests

```bash
# Run all tests
lua tests/run_tests.lua

# Run specific test file
lua tests/test_config.lua

# Run with verbose output
lua tests/run_tests.lua --verbose
```

---

## Documentation Requirements

### README.md Structure

1. **Title and Description**
2. **Features** (with screenshots/gifs)
3. **Requirements**
   - Neovim 0.8.0+
   - Codex CLI installed
4. **Installation**
   - Using lazy.nvim
   - Using packer.nvim
   - Manual installation
5. **Quick Start**
6. **Configuration**
   - Minimal example
   - Full example
   - Configuration reference
7. **Usage**
   - Commands
   - Keymaps
   - Context sending
8. **Advanced**
   - Multi-instance mode
   - MCP integration
   - Custom keymaps
9. **Troubleshooting**
10. **Contributing**
11. **License**

### Vim Help Documentation (doc/codex.txt)

```vimdoc
*codex.txt*  Integration with OpenAI Codex CLI for Neovim

Author: Your Name
License: Apache 2.0

==============================================================================
CONTENTS                                                      *codex-contents*

1. Introduction ........................... |codex-introduction|
2. Requirements ........................... |codex-requirements|
3. Installation ........................... |codex-installation|
4. Configuration .......................... |codex-configuration|
5. Commands ............................... |codex-commands|
6. Mappings ............................... |codex-mappings|
7. Functions .............................. |codex-functions|
8. Troubleshooting ........................ |codex-troubleshooting|

==============================================================================
INTRODUCTION                                              *codex-introduction*

Codex.nvim provides seamless integration between OpenAI's Codex CLI and
Neovim, enabling AI-assisted development directly within your editor.

Features:
- Toggle Codex terminal with configurable windows
- Multi-instance support (one per git repository)
- Automatic file change detection and reloading
- Send buffers, selections, and files to Codex
- Exec mode for non-interactive tasks
- MCP (Model Context Protocol) integration

... (continue with full documentation)
```

---

## Key Implementation Considerations

### Error Handling
- Always validate buffer/window IDs before use
- Provide helpful error messages to users
- Gracefully handle missing dependencies (git, Codex CLI)
- Fallback to defaults when config is invalid

### Performance
- Use `vim.schedule()` for deferred operations
- Avoid blocking operations in main thread
- Optimize file monitoring (timer-based, not constant)
- Cache git root lookups

### Compatibility
- Target Neovim 0.8.0+ (for nvim_create_user_command)
- Test on macOS, Linux, Windows
- Handle different shell environments
- Support both bash and zsh

### User Experience
- Clear notifications (not too many, not too few)
- Intuitive default keymaps
- Good documentation with examples
- Helpful error messages

### Code Quality
- Consistent style (use stylua for formatting)
- Comprehensive tests (aim for >80% coverage)
- Clear comments for complex logic
- Modular design for easy maintenance

---

## Comparison: claude-code.nvim vs codex.nvim

| Feature | claude-code.nvim | codex.nvim |
|---------|-----------------|------------|
| Base CLI command | `claude` | `codex` |
| Interactive mode | ✅ | ✅ |
| Exec mode | ❌ | ✅ NEW |
| Multi-instance | ✅ | ✅ |
| Git integration | ✅ | ✅ |
| File monitoring | ✅ | ✅ |
| Buffer sending | ❌ | ✅ NEW |
| Selection sending | ❌ | ✅ NEW |
| File sending | ❌ | ✅ NEW |
| MCP integration | ❌ | ✅ NEW |
| Split windows | ✅ | ✅ |
| Floating windows | ✅ | ✅ |
| Which-key support | ✅ | ✅ |
| Test coverage | ~95% | Target: >80% |

---

## Development Workflow

### Initial Setup
```bash
# Clone the repo
git clone https://github.com/yourusername/codex.nvim.git
cd codex.nvim

# Install Codex CLI if not already installed
npm install -g @openai/codex
# or
brew install --cask codex

# Test in local Neovim
nvim --cmd "set rtp+=." test_file.lua
```

### Development Cycle
1. Make changes to module
2. Run tests: `lua tests/run_tests.lua`
3. Test manually in Neovim
4. Format code: `stylua lua/`
5. Commit changes
6. Repeat

### Release Checklist
- [ ] All tests passing
- [ ] Version updated in version.lua
- [ ] CHANGELOG.md updated
- [ ] README.md reviewed
- [ ] Documentation complete
- [ ] Tag release in git
- [ ] Announce release

---

## Future Enhancements

### Short-term
- Add file tree context sending
- Implement project-wide context gathering
- Add Codex session management
- Improve MCP integration
- Add status line integration

### Long-term
- LSP integration (send diagnostics to Codex)
- Inline suggestions (like GitHub Copilot)
- Code action integration
- Test generation commands
- Documentation generation
- Diff mode for reviewing Codex changes

---

## Resources

### Codex Documentation
- Official docs: https://docs.codex.com
- CLI reference: https://github.com/openai/codex
- MCP specification: https://modelcontextprotocol.io

### Neovim API
- Neovim API docs: https://neovim.io/doc/user/api.html
- Lua guide: https://neovim.io/doc/user/lua-guide.html
- Plugin development: https://github.com/nanotee/nvim-lua-guide

### Reference Implementation
- claude-code.nvim: https://github.com/anthropics/claude-code.nvim
- Study architecture, patterns, and test structure

---

## FAQ

### Q: Why create a new plugin instead of forking claude-code.nvim?
A: Starting from scratch allows for:
- Clean git history
- Codex-specific features without backward compatibility concerns
- Learning experience in understanding the architecture
- No licensing/attribution complexities

### Q: Will this work with Codex free tier?
A: This plugin works with any Codex CLI installation. Codex is available with ChatGPT Plus, Pro, Team, Edu, and Enterprise plans.

### Q: Can I use both claude-code.nvim and codex.nvim?
A: Yes, they can coexist. Use different keymaps for each.

### Q: How do I contribute?
A: See CONTRIBUTING.md for guidelines. Pull requests welcome!

---

## License

Apache License 2.0

Copyright (c) 2025 [Your Name]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## Acknowledgments

- Inspired by and based on the architecture of [claude-code.nvim](https://github.com/anthropics/claude-code.nvim)
- Built for [Codex CLI](https://github.com/openai/codex) by OpenAI
- Community contributions and feedback

---

**This document serves as the complete specification for implementing codex.nvim. Follow it step-by-step, and you'll have a fully functional Neovim plugin for Codex integration.**
