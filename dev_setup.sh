#!/bin/bash
# Development setup script for codex.nvim
# Nastaví lokální development environment

set -e

echo "🔧 Codex.nvim Development Setup"
echo "================================"

# Zjisti adresář pluginu
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Plugin directory: $PLUGIN_DIR"

# Vytvoř Neovim dev config
DEV_CONFIG_DIR="$HOME/.config/nvim-codex-dev"
mkdir -p "$DEV_CONFIG_DIR"

cat > "$DEV_CONFIG_DIR/init.lua" << EOF
-- Codex.nvim Development Config
-- Použij tento config pro vývoj: nvim -u ~/.config/nvim-codex-dev/init.lua

-- Přidej lokální plugin do runtimepath
vim.opt.runtimepath:prepend('$PLUGIN_DIR')

-- Základní Neovim nastavení
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.autoread = true

-- Setup codex.nvim s debug konfigurací
require('codex').setup({
  window = {
    position = 'botright',
    split_ratio = 0.3,
    enter_insert = true,
  },
  refresh = {
    enable = true,
    show_notifications = true,  -- Zapni pro debugging
  },
  git = {
    multi_instance = true,
  },
  keymaps = {
    toggle = {
      normal = '<C-,>',
      terminal = '<C-,>',
    },
  },
})

-- Reload command pro rychlý vývoj
vim.api.nvim_create_user_command('CodexReload', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^codex') then
      package.loaded[name] = nil
    end
  end
  require('codex').setup()
  vim.notify('✅ Codex plugin reloaded!', vim.log.levels.INFO)
end, {})

-- Debug keymaps
vim.keymap.set('n', '<leader>ct', '<cmd>Codex<cr>', { desc = 'Toggle Codex' })
vim.keymap.set('n', '<leader>cd', '<cmd>CodexDebug<cr>', { desc = 'Codex Debug' })
vim.keymap.set('n', '<leader>cr', '<cmd>CodexReload<cr>', { desc = 'Codex Reload' })
vim.keymap.set('n', '<leader>cv', '<cmd>CodexVersion<cr>', { desc = 'Codex Version' })

-- Print welcome message
print('🚀 Codex.nvim Development Environment')
print('📖 Commands:')
print('  :Codex          - Toggle Codex terminal')
print('  :CodexDebug     - Show debug info')
print('  :CodexReload    - Reload plugin')
print('  :CodexVersion   - Show version')
print('')
print('⌨️  Keymaps:')
print('  <leader>ct      - Toggle Codex')
print('  <leader>cd      - Debug info')
print('  <leader>cr      - Reload plugin')
print('  <C-,>           - Toggle Codex')
print('')
print('📁 Plugin: $PLUGIN_DIR')
EOF

echo ""
echo "✅ Development config vytvořen!"
echo ""
echo "🚀 Jak začít:"
echo ""
echo "1. Spusť Neovim s dev configem:"
echo "   nvim -u ~/.config/nvim-codex-dev/init.lua"
echo ""
echo "2. Nebo přidej alias do ~/.zshrc nebo ~/.bashrc:"
echo "   alias nvim-dev='nvim -u ~/.config/nvim-codex-dev/init.lua'"
echo ""
echo "3. Testuj plugin:"
echo "   - Stiskni <C-,> pro toggle Codex"
echo "   - Spusť :CodexDebug pro debug info"
echo "   - Po změnách v kódu: :CodexReload"
echo ""
echo "📖 Více info: cat DEVELOPMENT.md"
echo ""

# Vytvoř také alias snippet
cat > "$DEV_CONFIG_DIR/alias.sh" << 'EOF'
# Přidej do ~/.zshrc nebo ~/.bashrc:
alias nvim-dev='nvim -u ~/.config/nvim-codex-dev/init.lua'
alias codex-dev='cd ~/git/private/codex.nvim && nvim-dev'
EOF

echo "💡 Tip: Pro přidání aliasů spusť:"
echo "   cat ~/.config/nvim-codex-dev/alias.sh >> ~/.zshrc"
echo "   source ~/.zshrc"
echo ""
