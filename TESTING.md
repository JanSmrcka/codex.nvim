# Testing codex.nvim

This document describes how to test the plugin.

## Manual Testing

1. Install the plugin using your preferred plugin manager
2. Open Neovim
3. Run `:lua require("codex").setup({ debug = true })`
4. Test the commands:
   - `:CodexStatus` - Should display current configuration
   - `:CodexDisable` - Should disable the plugin
   - `:CodexEnable` - Should enable the plugin
5. Run `:checkhealth codex` to verify the plugin is working correctly

## Expected Behavior

- The plugin should load without errors
- Commands should be available after loading
- Health check should pass all tests
- Setup function should accept configuration options
- Plugin should respect the `enabled` flag

## Automated Testing

To add automated tests, consider using:
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for Neovim Lua testing
- [vusted](https://github.com/notomo/vusted) for unit testing Lua code

Example test structure:

```lua
local codex = require("codex")

describe("codex.nvim", function()
  it("should load without errors", function()
    assert.is_not_nil(codex)
  end)
  
  it("should accept configuration", function()
    codex.setup({ enabled = false, debug = true })
    local config = codex.get_config()
    assert.is_false(config.enabled)
    assert.is_true(config.debug)
  end)
  
  it("should check enabled state", function()
    codex.setup({ enabled = true })
    assert.is_true(codex.is_enabled())
  end)
end)
```
