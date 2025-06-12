# ActivityWatch Context Tool

Add context annotations to your ActivityWatch data to track what you were working on.

## Components

- **aw-context**: Swift CLI tool for managing context annotations
- **aw-context-mcp-server**: MCP (Model Context Protocol) server that exposes the CLI functionality to AI assistants like Claude

## Installation

Prerequisites: macOS 12.0+, Swift 6.1+, ActivityWatch running on port 5600

### Using Swift Package Manager (Recommended)
```bash
git clone https://github.com/doozMen/activity-tagger.git
cd activity-tagger/aw-context-tool
swift package experimental-install

# Add to PATH if not already present
echo 'export PATH="$HOME/.swiftpm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Manual Installation
```bash
git clone https://github.com/doozMen/activity-tagger.git
cd activity-tagger/aw-context-tool
swift build -c release
sudo cp .build/release/aw-context /usr/local/bin/
```

## Usage

### Add Context
```bash
# Simple
aw-context add "Working on deep linking feature"

# With tags
aw-context add "Working on CA-5006 deep linking" --tags ios,bugfix
```

### Query Contexts
```bash
# Today (default)
aw-context query

# Specific date
aw-context query yesterday
aw-context query 2024-12-06

# Date range
aw-context query today --end tomorrow
```

### Search by Tag
```bash
aw-context search deep-linking
```

### Daily Summary
```bash
# Today
aw-context summary

# Specific date
aw-context summary --date 2025-06-12
```

### Enrich Activities
```bash
# Today (default)
aw-context enrich

# Specific date
aw-context enrich yesterday
aw-context enrich 2024-12-06

# Time range (assumes today)
aw-context enrich 09:00 --end 17:00

# Full control
aw-context enrich --start "2024-12-06 09:00" --end "2024-12-06 17:00"
```

## Data Storage

Contexts stored as JSON in `~/.aw-context/context-YYYY-MM-DD.json`

## MCP Server

The MCP server allows AI assistants to interact with your ActivityWatch contexts. See [aw-context-mcp-server/README.md](aw-context-mcp-server/README.md) for setup instructions.

## License

MIT