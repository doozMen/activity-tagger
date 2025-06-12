# ActivityWatch Context Tool

Add context annotations to your ActivityWatch data to track what you were working on.

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
# Today
aw-context query --start today

# Date range
aw-context query --start 2025-06-12 --end 2025-06-13
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
# Show activities with nearest context
aw-context enrich --start "09:00" --end "10:00"
```

## Data Storage

Contexts stored as JSON in `~/.aw-context/context-YYYY-MM-DD.json`

## License

MIT