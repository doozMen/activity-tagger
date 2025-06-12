# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-06

### Added
- Library target structure (`AWContextLib`) for better modularity
- Comprehensive test suite using Swift Testing framework
- Date parsing tests for natural language dates
- ContextManager tests for core functionality
- Version information accessible via `--version` flag
- Atomic file writes to prevent data corruption
- Support for natural language dates in `enrich` command ("today", "yesterday", "now")
- Optional start/end parameters for `enrich` command (defaults to today)
- `CLAUDE.md` file for AI-assisted development guidance
- Swift experimental install method in README

### Changed
- Restructured project into library and executable targets
- Improved `enrich` command with sensible defaults
- Updated README with experimental Swift package install command
- Enhanced JSON encoding with pretty printing and sorted keys

### Fixed
- JSON file corruption when multiple contexts are saved
- Concurrent file access issues in tests
- Missing public modifiers on library types

### Changed
- Query command now accepts date as first positional argument
- Query command --start and --end are now optional overrides

## [0.0.1] - 2024-12-05

### Added
- Initial release
- `add` command to add context annotations with optional tags
- `query` command to query contexts by date range
- `search` command to search contexts by tag
- `summary` command to generate daily summaries
- `enrich` command to show ActivityWatch events with nearest context
- Local JSON storage for contexts in `~/.aw-context/`
- Integration with ActivityWatch API
- Support for natural language dates ("today", "yesterday")
- ISO 8601 date formatting throughout
- UTC timezone handling for ActivityWatch compatibility