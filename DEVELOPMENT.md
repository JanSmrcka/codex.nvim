# Development Setup Guide

Tento návod ti ukáže, jak nastavit lokální vývoj pluginu codex.nvim pro debugging a testování.

## 🔧 Lokální Setup

### Metoda 1: Symlink do runtime path

Nejjednodušší způsob pro vývoj je vytvořit symlink:

```bash
# Vytvoř symlink v Neovim runtime path
mkdir -p ~/.local/share/nvim/site/pack/dev/start
ln -s ~/git/private/codex.nvim ~/.local/share/nvim/site/pack/dev/start/codex.nvim

# Restartuj Neovim
```

### Metoda 2: Přidání do runtimepath v configu

V tvém Neovim configu (např. `~/.config/nvim/init.lua` nebo pro claude-code.nvim: `~/git/private/tools/claude-code.nvim`):

```lua
-- Na začátek configu přidej:
vim.opt.runtimepath:prepend('~/git/private/codex.nvim')

-- Pak normálně setupuj plugin:
require('codex').setup({
  -- tvoje konfigurace
})
```

### Metoda 3: Lazy.nvim dev mode

Pokud používáš lazy.nvim, můžeš použít dev mode:

```lua
{
  'JanSmrcka/codex.nvim',
  dir = '~/git/private/codex.nvim',  -- Použije lokální kopii
  config = function()
    require('codex').setup({
      -- tvoje konfigurace
    })
  end,
}
```

### Metoda 4: Packer dev mode

Pro packer.nvim:

```lua
use {
  '~/git/private/codex.nvim',  -- Lokální cesta
  config = function()
    require('codex').setup()
  end
}
```

## 🐛 Debugging

### 1. Reload pluginu během vývoje

```lua
-- V Neovimu spusť:
:lua package.loaded['codex'] = nil
:lua package.loaded['codex.terminal'] = nil
:lua package.loaded['codex.config'] = nil
-- ... atd pro všechny moduly

-- Pak reload:
:lua require('codex').setup()
```

### 2. Quick reload funkce

Přidej si do configu helper funkci:

```lua
-- Přidej do init.lua
vim.api.nvim_create_user_command('CodexReload', function()
  -- Unload všechny codex moduly
  for name, _ in pairs(package.loaded) do
    if name:match('^codex') then
      package.loaded[name] = nil
    end
  end

  -- Reload plugin
  require('codex').setup({
    -- tvoje konfigurace
  })

  print('Codex plugin reloaded!')
end, {})
```

Potom stačí spustit: `:CodexReload`

### 3. Debug logging

Přidej do kódu debug výpisy:

```lua
-- V lua/codex/terminal.lua nebo jinde:
print('DEBUG: bufnr =', bufnr)
print('DEBUG: instance_id =', instance_id)
vim.notify('Debug message', vim.log.levels.INFO)
```

### 4. Kontrola stavu pluginu

```vim
:CodexDebug                    " Zobrazí stav pluginu
:lua =require('codex').codex   " Zobrazí interní stav
:messages                       " Zobrazí všechny zprávy/errory
```

## 🧪 Testování

### Ruční testování

```bash
# Otevři Neovim s lokální verzí pluginu
cd ~/git/private/codex.nvim
nvim --cmd "set rtp+=." test.lua
```

V Neovimu:

```vim
" Setup plugin
:lua require('codex').setup()

" Test základní funkčnosti
:Codex
:CodexVersion
:CodexDebug
```

### Testování v izolovaném prostředí

```bash
# Vytvoř minimální config pro testování
cat > /tmp/test_config.lua << 'EOF'
-- Minimální config
vim.opt.runtimepath:prepend('~/git/private/codex.nvim')

require('codex').setup({
  window = {
    position = 'botright',
    split_ratio = 0.3,
  },
})

print('Codex loaded!')
EOF

# Spusť Neovim s tímto configem
nvim -u /tmp/test_config.lua
```

## 📝 Workflow pro vývoj

1. **Edituj kód** v `~/git/private/codex.nvim/lua/codex/`
2. **Reload plugin** pomocí `:CodexReload`
3. **Testuj změny** pomocí `:Codex` nebo jiných příkazů
4. **Zkontroluj errory** pomocí `:messages`
5. **Commit změny** když vše funguje

## 🔍 Checklist pro debugging

- [ ] Plugin se načítá? → `:lua =require('codex')`
- [ ] Config je validní? → `:lua =require('codex').config`
- [ ] Codex CLI funguje? → `:!codex --version`
- [ ] Terminal se vytváří? → `:Codex`
- [ ] Nejsou errory? → `:messages`
- [ ] Buffery jsou validní? → `:CodexDebug`

## 🚀 Quick Start pro debugging

```lua
-- Přidej do ~/git/private/tools/claude-code.nvim nebo kde máš svůj config:

-- 1. Přidej lokální plugin do runtimepath
vim.opt.runtimepath:prepend('~/git/private/codex.nvim')

-- 2. Setup s debug konfigurací
require('codex').setup({
  window = {
    position = 'botright',
    split_ratio = 0.3,
  },
  refresh = {
    enable = true,
    show_notifications = true,  -- Zapni notifikace pro debugging
  },
  command = 'codex',  -- Nebo 'echo' pro testování bez Codex CLI
})

-- 3. Přidaj reload command
vim.api.nvim_create_user_command('CodexReload', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^codex') then
      package.loaded[name] = nil
    end
  end
  require('codex').setup()
  print('Codex reloaded!')
end, {})

-- 4. Keymapy pro rychlý přístup
vim.keymap.set('n', '<leader>ct', '<cmd>Codex<cr>', { desc = 'Toggle Codex' })
vim.keymap.set('n', '<leader>cd', '<cmd>CodexDebug<cr>', { desc = 'Codex Debug' })
vim.keymap.set('n', '<leader>cr', '<cmd>CodexReload<cr>', { desc = 'Codex Reload' })
```

## 💡 Tipy

1. **Používej print() pro debugging** - Výpisy se zobrazí v `:messages`
2. **Sleduj logy** - `:messages` je tvůj přítel
3. **Testuj změny postupně** - Reload po každé změně
4. **Git commit často** - Malé commity jsou lepší
5. **Používaj `:CodexDebug`** - Zobrazí stav všech instancí

## 🆘 Časté problémy

### "Module not found: codex"

```lua
-- Zkontroluj runtimepath:
:lua =vim.opt.runtimepath:get()

-- Přidej cestu:
:lua vim.opt.runtimepath:prepend('~/git/private/codex.nvim')
```

### "E5108: Invalid argument"

→ Toto už jsme opravili! Byla to deprecated Neovim API.

### Terminal se neotevře

```vim
" Zkontroluj Codex CLI:
:!which codex
:!codex --version

" Zkontroluj git root:
:!git rev-parse --show-toplevel
```

### Změny se neprojevují

```vim
" Reload všechny moduly:
:CodexReload

" Nebo restart Neovimu:
:qa
```

---

**Happy debugging!** 🎉

Pokud najdeš nějaký bug, otevři issue na: https://github.com/JanSmrcka/codex.nvim/issues
