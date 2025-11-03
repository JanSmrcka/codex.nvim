# Development Setup Guide

This guide shows how to set up local development for codex.nvim for debugging and testing.

## 🔧 Local Setup

### Method 1: Symlink to runtime path

The simplest way for development is to create a symlink:

```bash
# Create symlink in Neovim runtime path
mkdir -p ~/.local/share/nvim/site/pack/dev/start
ln -s /path/to/your/codex.nvim ~/.local/share/nvim/site/pack/dev/start/codex.nvim

# Restart Neovim
```

### Method 2: Add to runtimepath in config

In your Neovim config (e.g. `~/.config/nvim/init.lua`):

```lua
-- Add at the beginning of your config:
vim.opt.runtimepath:prepend('/path/to/your/codex.nvim')

-- Then setup the plugin normally:
require('codex').setup({
  -- your configuration
})
```

### Method 3: Lazy.nvim dev mode

If you're using lazy.nvim, you can use dev mode:

```lua
{
  'JanSmrcka/codex.nvim',
  dir = '/path/to/your/codex.nvim',  -- Use local copy
  config = function()
    require('codex').setup({
      -- your configuration
    })
  end,
}
```

### Method 4: Packer dev mode

For packer.nvim:

```lua
use {
  '/path/to/your/codex.nvim',  -- Local path
  config = function()
    require('codex').setup()
  end
}
```

## 🐛 Debugging

### 1. Reload plugin during development

```lua
-- In Neovim run:
:lua package.loaded['codex'] = nil
:lua package.loaded['codex.terminal'] = nil
:lua package.loaded['codex.config'] = nil
-- ... etc for all modules

-- Then reload:
:lua require('codex').setup()
```

### 2. Quick reload function

Add a helper function to your config:

```lua
-- Add to init.lua
vim.api.nvim_create_user_command('CodexReload', function()
  -- Unload all codex modules
  for name, _ in pairs(package.loaded) do
    if name:match('^codex') then
      package.loaded[name] = nil
    end
  end

  -- Reload plugin
  require('codex').setup({
    -- your configuration
  })

  print('Codex plugin reloaded!')
end, {})
```

Then just run: `:CodexReload`

### 3. Debug logging

Add debug prints to the code:

```lua
-- In lua/codex/terminal.lua or elsewhere:
print('DEBUG: bufnr =', bufnr)
print('DEBUG: instance_id =', instance_id)
vim.notify('Debug message', vim.log.levels.INFO)
```

### 4. Check plugin state

```vim
:CodexDebug                    " Show plugin state
:lua =require('codex').codex   " Show internal state
:messages                       " Show all messages/errors
```

## 🧪 Testing

### Manual testing

```bash
# Open Neovim with local plugin version
cd /path/to/your/codex.nvim
nvim --cmd "set rtp+=." test.lua
```

In Neovim:

```vim
" Setup plugin
:lua require('codex').setup()

" Test basic functionality
:Codex
:CodexVersion
:CodexDebug
```

### Testing in isolated environment

```bash
# Create minimal config for testing
cat > /tmp/test_config.lua << 'EOF'
-- Minimal config
vim.opt.runtimepath:prepend('/path/to/your/codex.nvim')

require('codex').setup({
  window = {
    position = 'botright vertical',
    split_ratio = 0.4,
  },
})

print('Codex loaded!')
EOF

# Run Neovim with this config
nvim -u /tmp/test_config.lua
```

## 📝 Development Workflow

1. **Edit code** in `lua/codex/`
2. **Reload plugin** using `:CodexReload`
3. **Test changes** using `:Codex` or other commands
4. **Check errors** using `:messages`
5. **Commit changes** when everything works

## 🔍 Debugging Checklist

- [ ] Does plugin load? → `:lua =require('codex')`
- [ ] Is config valid? → `:lua =require('codex').config`
- [ ] Does Codex CLI work? → `:!codex --version`
- [ ] Does terminal create? → `:Codex`
- [ ] Any errors? → `:messages`
- [ ] Are buffers valid? → `:CodexDebug`

## 🚀 Quick Start for Debugging

```lua
-- Add to your Neovim config:

-- 1. Add local plugin to runtimepath
vim.opt.runtimepath:prepend('/path/to/your/codex.nvim')

-- 2. Setup with debug configuration
require('codex').setup({
  window = {
    position = 'botright vertical',
    split_ratio = 0.4,
  },
  refresh = {
    enable = true,
    show_notifications = true,  -- Enable notifications for debugging
  },
  command = 'codex',  -- Or 'echo' for testing without Codex CLI
})

-- 3. Add reload command
vim.api.nvim_create_user_command('CodexReload', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^codex') then
      package.loaded[name] = nil
    end
  end
  require('codex').setup()
  print('Codex reloaded!')
end, {})

-- 4. Keymaps for quick access
vim.keymap.set('n', '<leader>ct', '<cmd>Codex<cr>', { desc = 'Toggle Codex' })
vim.keymap.set('n', '<leader>cd', '<cmd>CodexDebug<cr>', { desc = 'Codex Debug' })
vim.keymap.set('n', '<leader>cr', '<cmd>CodexReload<cr>', { desc = 'Codex Reload' })
```

## 💡 Tips

1. **Use print() for debugging** - Output appears in `:messages`
2. **Watch logs** - `:messages` is your friend
3. **Test changes incrementally** - Reload after each change
4. **Git commit often** - Small commits are better
5. **Use `:CodexDebug`** - Shows state of all instances

## 🆘 Common Issues

### "Module not found: codex"

```lua
-- Check runtimepath:
:lua =vim.opt.runtimepath:get()

-- Add path:
:lua vim.opt.runtimepath:prepend('/path/to/your/codex.nvim')
```

### "E5108: Invalid argument"

→ This has been fixed! It was deprecated Neovim API.

### Terminal doesn't open

```vim
" Check Codex CLI:
:!which codex
:!codex --version

" Check git root:
:!git rev-parse --show-toplevel
```

### Changes don't take effect

```vim
" Reload all modules:
:CodexReload

" Or restart Neovim:
:qa
```

## 🔧 Advanced Setup

### Auto-reload on file save

Add this to your config for automatic reloading:

```lua
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*/lua/codex/*.lua',
  callback = function()
    vim.cmd('CodexReload')
  end,
})
```

### Debug with verbose output

```lua
require('codex').setup({
  command_variants = {
    verbose = {
      enabled = true,
      flags = '--verbose',
    },
  },
})
```

Then use `:CodexVerbose` to see detailed output.

### Test without Codex CLI

For testing plugin functionality without Codex CLI installed:

```lua
require('codex').setup({
  command = 'echo',  -- Just echo instead of running codex
})
```

---

**Happy debugging!** 🎉

If you find any bugs, please open an issue: https://github.com/JanSmrcka/codex.nvim/issues
