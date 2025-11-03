# Contributing to codex.nvim

Thank you for your interest in contributing to codex.nvim! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive. We want to foster an open and welcoming environment for everyone.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Neovim version** (`:version`)
- **Codex CLI version** (`codex --version`)
- **Your configuration** (relevant parts)
- **Error messages** or logs (if any)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

- Use a clear and descriptive title
- Provide a detailed description of the proposed functionality
- Explain why this enhancement would be useful
- Include code examples if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Follow the coding style** (see below)
3. **Add tests** if applicable
4. **Update documentation** if you change functionality
5. **Ensure all tests pass**
6. **Write a clear commit message**

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/codex.nvim.git
cd codex.nvim

# Create a branch for your changes
git checkout -b feature/my-new-feature

# Test locally in Neovim
nvim --cmd "set rtp+=." test_file.lua
```

## Project Structure

```
codex.nvim/
├── lua/codex/
│   ├── init.lua           # Main entry point
│   ├── config.lua         # Configuration management
│   ├── terminal.lua       # Terminal management
│   ├── git.lua            # Git integration
│   ├── file_refresh.lua   # File monitoring
│   ├── commands.lua       # Command registration
│   ├── keymaps.lua        # Keymap management
│   ├── context.lua        # Context sending
│   ├── mcp.lua            # MCP integration
│   └── version.lua        # Version info
├── doc/                   # Vim help documentation
├── tests/                 # Test suite
└── examples/              # Example configurations
```

## Coding Style

### Lua Style Guidelines

- Use **2 spaces** for indentation
- Follow **snake_case** for function and variable names
- Use **descriptive names** (avoid abbreviations)
- Add **comments** for complex logic
- Keep functions **focused** and **small**
- Use **local** for all variables except module exports

### Format with stylua

```bash
# Install stylua
cargo install stylua

# Format all Lua files
stylua lua/
```

### Example Code Style

```lua
-- Good: Clear, descriptive, well-commented
local function validate_window_config(config)
  if type(config.window) ~= 'table' then
    return false, 'window must be a table'
  end

  local split_ratio = config.window.split_ratio
  if type(split_ratio) ~= 'number' or split_ratio <= 0 or split_ratio >= 1 then
    return false, 'window.split_ratio must be between 0 and 1'
  end

  return true
end

-- Bad: Unclear, no validation messages
local function valWin(c)
  if type(c.w) ~= 'table' then return false end
  if type(c.w.sr) ~= 'number' then return false end
  return true
end
```

## Documentation

### Code Comments

- Add docstrings to all public functions
- Use LuaCATS annotations where helpful
- Explain **why**, not just **what**

Example:
```lua
-- Send current buffer to Codex
-- @param codex_state table The plugin state
-- @param config table The plugin configuration
function M.send_buffer(codex_state, config)
  -- Implementation
end
```

### Vim Help Documentation

When adding new features, update `doc/codex.txt`:

- Add command documentation
- Add function documentation
- Include examples
- Update table of contents

### README Updates

Update `README.md` for:

- New features
- Configuration changes
- New commands or keymaps
- Breaking changes

## Testing

### Manual Testing

Test your changes in a real Neovim environment:

```lua
-- In your Neovim config
vim.opt.runtimepath:append('~/path/to/your/codex.nvim')
require('codex').setup({
  -- your test config
})
```

### Test Checklist

Before submitting a PR, verify:

- [ ] Plugin loads without errors
- [ ] All commands work as expected
- [ ] Keymaps function correctly
- [ ] Configuration validation works
- [ ] Error messages are clear and helpful
- [ ] No Lua errors in `:messages`
- [ ] Documentation is updated
- [ ] Code is formatted with stylua

## Commit Messages

Follow conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(context): Add support for sending file ranges

- Allow sending specific line ranges from files
- Add :CodexSendRange command
- Update documentation

Closes #42
```

```
fix(terminal): Handle edge case when git root not found

When not in a git repository, fall back to current working directory
instead of failing silently.

Fixes #38
```

## Release Process

(For maintainers)

1. Update version in `lua/codex/version.lua`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag -a v0.2.0 -m "Version 0.2.0"`
4. Push tag: `git push origin v0.2.0`
5. Create GitHub release with changelog

## Questions?

- Open an issue with the `question` label
- Check existing discussions
- Review the documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to codex.nvim! 🎉
