# ActivityWatch Context MCP Server

An MCP (Model Context Protocol) server that provides AI assistants with access to ActivityWatch context annotations through the `aw-context` CLI tool.

## Features

- **Add Context**: Add context annotations with optional tags
- **Query Contexts**: Query contexts by date or date range
- **Search Contexts**: Search contexts by tag
- **Context Summary**: Get daily summaries of contexts
- **Enrich Activities**: Enrich ActivityWatch events with context information

## Prerequisites

- Node.js 18 or higher
- `aw-context` CLI tool installed and available in PATH
- ActivityWatch running on localhost:5600 (for enrichment features)

## Installation

1. Clone this repository
2. Install dependencies:
```bash
cd aw-context-mcp-server
npm install
```

3. Build the server:
```bash
npm run build
```

## Usage

### With Claude Desktop

Add the following to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "aw-context": {
      "command": "node",
      "args": ["/path/to/aw-context-mcp-server/dist/index.js"]
    }
  }
}
```

### Available Tools

#### `add-context`
Add a new context annotation.

Parameters:
- `context` (required): The context description
- `tags` (optional): Array of tags

Example:
```
Add context "Working on MCP server implementation" with tags ["development", "mcp"]
```

#### `query-contexts`
Query contexts by date or date range.

Parameters:
- `date` (optional): Date to query (default: "today")
- `start` (optional): Start date for range query
- `end` (optional): End date for range query

Examples:
```
Query contexts for today
Query contexts from "2024-03-01" to "2024-03-15"
```

#### `search-contexts`
Search contexts by tag.

Parameters:
- `tag` (required): Tag to search for

Example:
```
Search contexts with tag "meeting"
```

#### `context-summary`
Get a summary of contexts for a specific date.

Parameters:
- `date` (optional): Date to summarize (default: "today")

Example:
```
Get context summary for yesterday
```

#### `enrich-activities`
Enrich ActivityWatch events with context annotations.

Parameters:
- `date` (optional): Date to enrich (default: "today")
- `start` (optional): Start time for enrichment
- `end` (optional): End time for enrichment
- `window` (optional): Context window in minutes

Example:
```
Enrich activities for today with a 30 minute context window
```

## Development

- `npm run dev` - Run TypeScript compiler in watch mode
- `npm test` - Run tests
- `npm run build` - Build for production

## License

MIT