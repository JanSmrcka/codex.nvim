-- commands.lua - Neovim command registration
-- Registers all user commands for the plugin

local M = {}

-- Register all plugin commands
-- @param plugin table The plugin instance (with all methods)
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
    vim.notify('codex.nvim version: ' .. version, vim.log.levels.INFO)
  end, {
    desc = 'Show codex.nvim version',
  })

  -- Debug command (useful for development)
  vim.api.nvim_create_user_command('CodexDebug', function()
    local lines = {
      'codex.nvim Debug Information',
      '',
      'Version: ' .. plugin.get_version(),
      'Instances:',
    }

    for instance_id, bufnr in pairs(plugin.codex.instances) do
      local is_valid = vim.api.nvim_buf_is_valid(bufnr)
      table.insert(
        lines,
        string.format('  %s: buffer %d (valid: %s)', instance_id, bufnr, tostring(is_valid))
      )
    end

    table.insert(lines, '')
    table.insert(lines, 'Current instance: ' .. tostring(plugin.codex.current_instance))
    table.insert(lines, 'Saved updatetime: ' .. tostring(plugin.codex.saved_updatetime))

    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, {
    desc = 'Show debug information',
  })
end

return M
