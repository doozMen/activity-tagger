# ActivityWatch Context Tool

A Swift command-line tool that adds context annotations to ActivityWatch data, helping you track what you were working on during different time periods.

## Overview

`aw-context` integrates with [ActivityWatch](https://activitywatch.net/) to let you:

- Add contextual notes about what you're working on
- Tag your work sessions for easier categorization
- Query past contexts by date range or tags
- Generate work summaries that combine ActivityWatch data with your context annotations
- View enriched activity logs that show which applications you used alongside your work context

## Features

- **Context Tracking**: Add timestamped context entries with optional tags
- **JSON Storage**: Contexts stored locally in `~/.aw-context/` as daily JSON files
- **ActivityWatch Integration**: Connects to your local ActivityWatch server to enrich application usage data
- **Flexible Queries**: Search by date range, tags, or view summaries
- **Time Window Matching**: Automatically associates contexts with nearby activities (default: 30-minute window)

## Installation

### Prerequisites

- macOS 12.0 or later
- Swift 6.1 or later
- ActivityWatch running locally on port 5600

### Build from Source

```bash
git clone https://github.com/doozMen/activity-tagger.git
cd activity-tagger/aw-context-tool
swift build -c release
sudo cp .build/release/aw-context /usr/local/bin/
```

## Usage

### Add Context

Record what you're working on:

```bash
# Simple context
aw-context add "Working on deep linking feature"

# With tags
aw-context add "Working on CA-5006 deep linking tracking" --tags ios,deep-linking,bugfix
```

### Query Contexts

View contexts from a specific date range:

```bash
# Today's contexts
aw-context query --start today

# Date range
aw-context query --start 2025-06-12 --end 2025-06-13

# Yesterday
aw-context query --start yesterday
```

### Search by Tag

Find all contexts with a specific tag:

```bash
aw-context search deep-linking
```

### Daily Summary

Generate a work summary combining ActivityWatch data with your contexts:

```bash
# Today's summary
aw-context summary

# Specific date
aw-context summary --date 2025-06-12
```

Output example:
```
Application Summary for 2025-06-12:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Xcode: 68 minutes
  Contexts: Working on CA-5006 deep linking tracking

Slack: 38 minutes
  Contexts: A-team standup discussion
```

### Enriched Activity View

View ActivityWatch events with nearest context:

```bash
# Time range with context
aw-context enrich --start "09:00" --end "10:00"

# With custom time window (default: 30 minutes)
aw-context enrich --start "09:00" --end "10:00" --window 60
```

Output example:
```
09:03:15 | Xcode - CueEnvironment.swift | Context: Working on CA-5006 deep linking tracking
09:06:30 | Slack - Huddle with Jonah | Context: Discussing implementation approach
```

## Data Storage

Context data is stored in JSON files at:
- `~/.aw-context/context-YYYY-MM-DD.json`

Each context entry contains:
- Unique ID
- Timestamp
- Context description
- Tags array

## Integration with ActivityWatch

The tool connects to ActivityWatch's REST API at `http://localhost:5600` to:
- Fetch window tracking data
- Match contexts with application usage
- Generate enriched activity summaries

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details.