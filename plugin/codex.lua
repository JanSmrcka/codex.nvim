-- codex.nvim plugin entry point
-- Prevents the plugin from being loaded multiple times
if vim.g.loaded_codex then
  return
end
vim.g.loaded_codex = true

-- Create user commands
vim.api.nvim_create_user_command("CodexEnable", function()
  require("codex").setup({ enabled = true })
  print("codex.nvim enabled")
end, { desc = "Enable codex.nvim plugin" })

vim.api.nvim_create_user_command("CodexDisable", function()
  require("codex").setup({ enabled = false })
  print("codex.nvim disabled")
end, { desc = "Disable codex.nvim plugin" })

vim.api.nvim_create_user_command("CodexStatus", function()
  local codex = require("codex")
  local config = codex.get_config()
  print("codex.nvim status:", vim.inspect(config))
end, { desc = "Show codex.nvim status" })
