# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the ActivityWatch Context Tool (aw-context), a Swift command-line tool that adds context annotations to ActivityWatch data. It allows users to track what they were working on at specific times, add tags, and generate enriched activity reports.

## Common Development Commands

### Build Commands

```bash
# Debug build
swift build

# Release build (optimized)
swift build -c release

# Run the tool directly
swift run aw-context [command]

# Install to system (after release build)
sudo cp .build/release/aw-context /usr/local/bin/
```

### Development Workflow

```bash
# Clean build artifacts
swift package clean

# Update dependencies
swift package update

# Resolve dependencies
swift package resolve

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture

### Technology Stack
- **Language**: Swift 6.1+
- **Platform**: macOS 15+ (Sequoia)
- **Dependencies**:
  - `swift-argument-parser` (1.3.0+) - CLI framework
  - `async-http-client` (1.19.0+) - HTTP client for ActivityWatch API

### Code Structure
- **`Sources/AWContext/`** - All source code
  - `aw-context.swift` - Main entry point with CLI definition
  - `Commands.swift` - Command implementations (Add, Query, Search, Summary, Enrich)
  - `ContextManager.swift` - Core logic for managing contexts and file operations
  - `Models.swift` - Data models (Context, ActivityWatchEvent)
  - `ActivityWatchClient.swift` - HTTP client for ActivityWatch API

### Key Technical Details

1. **Data Storage**: Contexts are stored as JSON files in `~/.aw-context/` with format `context-YYYY-MM-DD.json`

2. **Timezone Handling**: Critical - ActivityWatch stores all timestamps in UTC. The tool handles timezone conversions for display.

3. **Command Pattern**: Uses Swift Argument Parser's command pattern for subcommands:
   - `add` - Add a new context
   - `query` - Query contexts by date range
   - `search` - Search contexts by tags
   - `summary` - Generate daily summaries
   - `enrich` - Show contexts for ActivityWatch events

4. **ActivityWatch Integration**: 
   - Connects to ActivityWatch at `http://localhost:5600`
   - Uses buckets: `aw-watcher-window_` and `aw-watcher-afk_`
   - Implements proper error handling for API failures

5. **Async/Await**: All HTTP operations use Swift's async/await concurrency model

## Important Notes

- No test suite currently exists - when adding tests, use Swift Testing (not XCTest)
- ActivityWatch must be running on localhost:5600 for enrichment features
- All timestamps are handled in UTC internally and converted for display
- The tool uses ISO 8601 date formatting throughout