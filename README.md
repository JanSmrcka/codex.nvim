# codex.nvim

A Neovim plugin template.

## Requirements

- Neovim >= 0.9.0

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "JanSmrcka/codex.nvim",
  config = function()
    require("codex").setup({
      enabled = true,
      debug = false,
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "JanSmrcka/codex.nvim",
  config = function()
    require("codex").setup({
      enabled = true,
      debug = false,
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'JanSmrcka/codex.nvim'
```

Then add to your init.lua:

```lua
require("codex").setup({
  enabled = true,
  debug = false,
})
```

## Configuration

The plugin accepts the following configuration options:

- `enabled` (boolean, default: `true`): Enable or disable the plugin
- `debug` (boolean, default: `false`): Enable debug mode for verbose logging

### Example configuration

```lua
require("codex").setup({
  enabled = true,
  debug = false,
})
```

## Commands

The plugin provides the following commands:

- `:CodexEnable` - Enable the plugin
- `:CodexDisable` - Disable the plugin
- `:CodexStatus` - Show current plugin status and configuration

## Health Check

Run `:checkhealth codex` to check if the plugin is installed and configured correctly.

## License

MIT