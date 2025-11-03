# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-03

### Added

- Initial release of codex.nvim
- Multi-instance support (one Codex per git repository)
- Git integration with automatic git root detection
- Terminal management with split and floating window support
- File monitoring and automatic reloading
- Context sending (buffers, selections, and files)
- Multiple send methods (stdin, clipboard, file)
- Exec mode for non-interactive commands
- MCP (Model Context Protocol) integration
- Comprehensive configuration system with validation
- Full keyboard navigation support
- Command variants (continue, resume, verbose)
- which-key integration (v2 and v3 compatible)
- Complete Vim help documentation
- Debug command for troubleshooting

### Commands

- `:Codex` - Toggle Codex terminal
- `:CodexContinue` - Toggle with --continue flag
- `:CodexResume` - Toggle with --resume flag
- `:CodexVerbose` - Toggle with --verbose flag
- `:CodexExec` - Execute non-interactive command
- `:CodexSendBuffer` - Send current buffer
- `:CodexSendSelection` - Send visual selection
- `:CodexSendFile` - Send specific file
- `:CodexVersion` - Show plugin version
- `:CodexMcpList` - List MCP servers
- `:CodexMcpInfo` - Show MCP server info
- `:CodexDebug` - Show debug information

### Configuration

- Window configuration (split/float, size, position)
- File refresh settings (updatetime, polling interval)
- Git integration options
- Context management (method, max lines)
- MCP integration settings
- Customizable keymaps for all functions
- Terminal navigation and scrolling

### Documentation

- Comprehensive README with examples
- Complete Vim help documentation (`:help codex`)
- Example configuration file
- Contributing guidelines

## [0.0.1] - 2025-11-03

### Added

- Project structure and initial setup
- MIT License
- Basic README

[Unreleased]: https://github.com/yourusername/codex.nvim/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/codex.nvim/releases/tag/v0.1.0
[0.0.1]: https://github.com/yourusername/codex.nvim/releases/tag/v0.0.1
