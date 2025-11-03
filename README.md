# codex.nvim

<div align="center">

**Seamless OpenAI Codex CLI integration for Neovim**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)](https://neovim.io)

</div>

## ✨ Features

- **🚀 Multi-Instance Support**: Separate Codex instances per git repository
- **📁 Git Integration**: Automatically uses git root as working directory
- **🔄 Auto File Reload**: Monitors and reloads files modified by Codex
- **📤 Context Sending**: Send buffers, selections, or files to Codex
- **⚡ Exec Mode**: Run non-interactive Codex commands
- **🔌 MCP Support**: Integration with Model Context Protocol servers
- **🪟 Flexible Windows**: Choose between split or floating windows
- **⌨️ Full Keymap Support**: Customizable keybindings with which-key integration

## 📋 Requirements

- **Neovim** >= 0.8.0
- **Codex CLI** installed and configured
  - Install via npm: `npm install -g @openai/codex`
  - Or via Homebrew: `brew install --cask codex`
- **Git** (optional, for multi-instance support)
- **ChatGPT Plus/Pro/Team/Enterprise** subscription (for Codex access)

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'JanSmrcka/codex.nvim',
  config = function()
    require('codex').setup({
      -- your configuration here (optional)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'JanSmrcka/codex.nvim',
  config = function()
    require('codex').setup()
  end
}
```

### Manual Installation

```bash
git clone https://github.com/JanSmrcka/codex.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/codex.nvim
```

## 🚀 Quick Start

### Minimal Configuration

```lua
require('codex').setup()
```

Then use `<C-,>` to toggle the Codex terminal, or run `:Codex`.

### Recommended Configuration

```lua
require('codex').setup({
  window = {
    position = 'botright',  -- or 'float' for floating window
    split_ratio = 0.3,
  },
  keymaps = {
    toggle = {
      normal = '<C-,>',
      terminal = '<C-,>',
    },
    context = {
      send_buffer = '<leader>cb',
      send_selection = '<leader>cs',
    },
  },
})
```

## ⚙️ Configuration

### Default Configuration

<details>
<summary>Click to expand full default configuration</summary>

```lua
require('codex').setup({
  -- Terminal window configuration
  window = {
    split_ratio = 0.3,              -- Size of split (0.0-1.0)
    position = 'botright',          -- 'botright', 'topleft', 'vertical', 'float'
    enter_insert = true,            -- Enter insert mode when opening
    start_in_normal_mode = false,   -- Override enter_insert
    hide_numbers = true,            -- Hide line numbers
    hide_signcolumn = true,         -- Hide sign column

    -- Floating window options (when position = 'float')
    float = {
      width = '80%',                -- Width (number or percentage)
      height = '80%',               -- Height
      row = 'center',               -- Row position
      col = 'center',               -- Column position
      border = 'rounded',           -- Border style
      relative = 'editor',          -- Relative to 'editor' or 'cursor'
    },
  },

  -- File refresh configuration
  refresh = {
    enable = true,                  -- Enable file monitoring
    updatetime = 100,               -- Vim updatetime while active (ms)
    timer_interval = 1000,          -- Polling interval (ms)
    show_notifications = false,     -- Notify on file changes
  },

  -- Git integration
  git = {
    use_git_root = true,            -- Use git root as cwd
    multi_instance = true,          -- One instance per repo
  },

  -- Shell commands
  shell = {
    separator = ' && ',             -- Command separator
    pushd_cmd = 'pushd',           -- Directory change command
    popd_cmd = 'popd',             -- Directory restore command
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
```

</details>

## 📖 Usage

### Commands

| Command | Description |
|---------|-------------|
| `:Codex` | Toggle Codex terminal |
| `:CodexContinue` | Toggle with `--continue` flag |
| `:CodexResume` | Toggle with `--resume` flag |
| `:CodexVerbose` | Toggle with `--verbose` flag |
| `:CodexExec [prompt]` | Execute non-interactive command |
| `:CodexSendBuffer` | Send current buffer to Codex |
| `:CodexSendSelection` | Send visual selection to Codex |
| `:CodexSendFile [path]` | Send specific file to Codex |
| `:CodexVersion` | Show plugin version |
| `:CodexMcpList` | List MCP servers (if enabled) |

### Default Keymaps

| Mode | Keymap | Action |
|------|--------|--------|
| Normal | `<C-,>` | Toggle Codex terminal |
| Terminal | `<C-,>` | Toggle Codex terminal |
| Normal | `<leader>cc` | Codex continue |
| Normal | `<leader>cr` | Codex resume |
| Normal | `<leader>cv` | Codex verbose |
| Normal | `<leader>cx` | Codex exec |
| Normal | `<leader>cb` | Send buffer to Codex |
| Visual | `<leader>cs` | Send selection to Codex |
| Terminal | `<C-h/j/k/l>` | Navigate to adjacent window |
| Terminal | `<C-b/f>` | Scroll page up/down |

## 🎯 Use Cases

### Send Code for Review

1. Open a file with code
2. Select the code in visual mode
3. Press `<leader>cs` to send to Codex
4. Ask Codex to review or improve it

### Quick Fixes with Exec Mode

```vim
:CodexExec Fix all TypeScript errors in this file
```

### Context-Aware Assistance

```lua
-- Send entire buffer for context
vim.keymap.set('n', '<leader>ca', function()
  require('codex').send_buffer()
  require('codex').toggle()
end, { desc = 'Send buffer and open Codex' })
```

## 🏗️ Architecture

codex.nvim is built with a modular architecture:

- **`init.lua`**: Main entry point and public API
- **`config.lua`**: Configuration management and validation
- **`terminal.lua`**: Terminal and process management
- **`git.lua`**: Git repository detection
- **`file_refresh.lua`**: File change monitoring
- **`commands.lua`**: Neovim command registration
- **`keymaps.lua`**: Keyboard binding management
- **`context.lua`**: Buffer/file context sending
- **`mcp.lua`**: MCP server integration
- **`version.lua`**: Version information

## 🔧 Advanced Usage

### Multi-Instance Mode

When `git.multi_instance = true`, codex.nvim maintains separate Codex instances for each git repository:

```lua
-- Project A
cd ~/projects/project-a
nvim
:Codex  -- Opens instance for project-a

-- Project B (in another terminal)
cd ~/projects/project-b
nvim
:Codex  -- Opens separate instance for project-b
```

### Custom Context Sending

```lua
-- Send multiple files
local codex = require('codex')
codex.send_file('src/main.lua')
codex.send_file('src/config.lua')
codex.toggle()
```

### Floating Window

```lua
require('codex').setup({
  window = {
    position = 'float',
    float = {
      width = '90%',
      height = '90%',
      border = 'double',
    },
  },
})
```

## 🐛 Troubleshooting

### Codex command not found

Ensure Codex CLI is installed and in your PATH:

```bash
codex --version
```

If not installed:

```bash
npm install -g @openai/codex
# or
brew install --cask codex
```

### File changes not auto-reloading

Make sure `autoread` is enabled:

```lua
vim.opt.autoread = true
```

### Terminal not opening

Check Neovim version:

```vim
:version
```

codex.nvim requires Neovim >= 0.8.0

### Keymaps not working

Verify there are no conflicting keymaps:

```vim
:verbose map <C-,>
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
git clone https://github.com/JanSmrcka/codex.nvim.git
cd codex.nvim

# Test locally
nvim --cmd "set rtp+=." test_file.lua
```

### Running Tests

```bash
lua tests/run_tests.lua
```

## 📚 Inspiration

This plugin is inspired by and based on the architecture of [claude-code.nvim](https://github.com/anthropics/claude-code.nvim), adapted for OpenAI's Codex CLI.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- [claude-code.nvim](https://github.com/anthropics/claude-code.nvim) for the architectural inspiration
- [Codex CLI](https://github.com/openai/codex) by OpenAI
- The Neovim community for excellent documentation and support

---

<div align="center">

**[Documentation](doc/codex.txt)** • **[Issues](https://github.com/JanSmrcka/codex.nvim/issues)** • **[Discussions](https://github.com/JanSmrcka/codex.nvim/discussions)**

Made with ❤️ for the Neovim community

</div>
