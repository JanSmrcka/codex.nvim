#!/bin/bash
# Development setup script for codex.nvim
# Sets up local development environment

set -e

echo "🔧 Codex.nvim Development Setup"
echo "================================"

# Detect plugin directory
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📁 Plugin directory: $PLUGIN_DIR"

# Create Neovim dev config
DEV_CONFIG_DIR="$HOME/.config/nvim-codex-dev"
mkdir -p "$DEV_CONFIG_DIR"

cat > "$DEV_CONFIG_DIR/init.lua" << EOF
-- Codex.nvim Development Config
-- Use this config for development: nvim -u ~/.config/nvim-codex-dev/init.lua

-- Add local plugin to runtimepath
vim.opt.runtimepath:prepend('$PLUGIN_DIR')

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.autoread = true

-- Setup codex.nvim with debug configuration
require('codex').setup({
  window = {
    position = 'botright vertical',
    split_ratio = 0.4,
    enter_insert = true,
  },
  refresh = {
    enable = true,
    show_notifications = true,  -- Enable for debugging
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

-- Reload command for quick development
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
echo "✅ Development config created!"
echo ""
echo "🚀 How to start:"
echo ""
echo "1. Run Neovim with dev config:"
echo "   nvim -u ~/.config/nvim-codex-dev/init.lua"
echo ""
echo "2. Or add alias to ~/.zshrc or ~/.bashrc:"
echo "   alias nvim-dev='nvim -u ~/.config/nvim-codex-dev/init.lua'"
echo ""
echo "3. Test the plugin:"
echo "   - Press <C-,> to toggle Codex"
echo "   - Run :CodexDebug for debug info"
echo "   - After code changes: :CodexReload"
echo ""
echo "📖 More info: cat DEVELOPMENT.md"
echo ""

# Create alias snippet
cat > "$DEV_CONFIG_DIR/alias.sh" << 'EOF'
# Add to ~/.zshrc or ~/.bashrc:
alias nvim-dev='nvim -u ~/.config/nvim-codex-dev/init.lua'
alias codex-dev='cd $(git rev-parse --show-toplevel) && nvim-dev'
EOF

echo "💡 Tip: To add aliases run:"
echo "   cat ~/.config/nvim-codex-dev/alias.sh >> ~/.zshrc"
echo "   source ~/.zshrc"
echo ""
