#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { execSync } from "child_process";
import { ContextEntry, ActivityWatchEvent, EnrichedEvent } from "./types.js";

// Check if aw-context CLI is available
function checkAwContextInstalled(): boolean {
  try {
    execSync("which aw-context", { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

// Execute aw-context commands
function executeAwContext(args: string[]): string {
  try {
    const result = execSync(`aw-context ${args.join(" ")}`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return result.trim();
  } catch (error: any) {
    throw new Error(`aw-context command failed: ${error.message}`);
  }
}

// Parse the output from various aw-context commands
export function parseContextList(output: string): ContextEntry[] {
  const lines = output.split("\n").filter(line => line.trim());
  const entries: ContextEntry[] = [];
  
  for (const line of lines) {
    // Expected format: "ID: <id> | Time: <time> | Context: <context> | Tags: <tags>"
    const match = line.match(/ID:\s*(\S+)\s*\|\s*Time:\s*([^|]+)\s*\|\s*Context:\s*([^|]+)\s*\|\s*Tags:\s*(.+)/);
    if (match) {
      const [_, id, timestamp, context, tagsStr] = match;
      const tags = tagsStr.split(",").map(t => t.trim()).filter(t => t);
      entries.push({
        id: id.trim(),
        timestamp: timestamp.trim(),
        context: context.trim(),
        tags
      });
    }
  }
  
  return entries;
}

export function parseEnrichedEvents(output: string): EnrichedEvent[] {
  const lines = output.split("\n").filter(line => line.trim());
  const events: EnrichedEvent[] = [];
  
  for (const line of lines) {
    // Expected format: "HH:MM:SS | App - Title | Context: <context>"
    const match = line.match(/(\d{2}:\d{2}:\d{2})\s*\|\s*([^-]+)\s*-\s*([^|]+)(?:\s*\|\s*Context:\s*(.+))?/);
    if (match) {
      const [_, time, app, title, context] = match;
      events.push({
        timestamp: time,
        duration: 0, // Duration not provided in enrich output
        data: {
          app: app.trim(),
          title: title.trim()
        },
        context: context?.trim()
      });
    }
  }
  
  return events;
}

const server = new Server(
  {
    name: "aw-context-mcp-server",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tool schemas
const AddContextSchema = z.object({
  context: z.string().describe("The context description"),
  tags: z.array(z.string()).optional().describe("Optional tags for the context"),
});

const QueryContextSchema = z.object({
  date: z.string().optional().default("today").describe("Date to query (e.g., 'today', 'yesterday', '2024-03-15')"),
  start: z.string().optional().describe("Start date for range query"),
  end: z.string().optional().describe("End date for range query"),
});

const SearchContextSchema = z.object({
  tag: z.string().describe("Tag to search for"),
});

const SummarySchema = z.object({
  date: z.string().optional().default("today").describe("Date to summarize"),
});

const EnrichSchema = z.object({
  date: z.string().optional().default("today").describe("Date to enrich"),
  start: z.string().optional().describe("Start time for enrichment"),
  end: z.string().optional().describe("End time for enrichment"),
  window: z.number().optional().describe("Context window in minutes"),
});

// Handle tool listing
server.setRequestHandler(ListToolsRequestSchema, async () => {
  if (!checkAwContextInstalled()) {
    return {
      tools: [{
        name: "aw-context-not-installed",
        description: "aw-context CLI is not installed. Please install it first.",
        inputSchema: {
          type: "object",
          properties: {},
        },
      }],
    };
  }

  return {
    tools: [
      {
        name: "add-context",
        description: "Add a new context annotation with optional tags",
        inputSchema: {
          type: "object",
          properties: {
            context: {
              type: "string",
              description: "The context description",
            },
            tags: {
              type: "array",
              items: {
                type: "string",
              },
              description: "Optional tags for the context",
            },
          },
          required: ["context"],
        },
      },
      {
        name: "query-contexts",
        description: "Query context entries by date or date range",
        inputSchema: {
          type: "object",
          properties: {
            date: {
              type: "string",
              description: "Date to query (e.g., 'today', 'yesterday', '2024-03-15')",
              default: "today",
            },
            start: {
              type: "string",
              description: "Start date for range query",
            },
            end: {
              type: "string",
              description: "End date for range query",
            },
          },
        },
      },
      {
        name: "search-contexts",
        description: "Search contexts by tag",
        inputSchema: {
          type: "object",
          properties: {
            tag: {
              type: "string",
              description: "Tag to search for",
            },
          },
          required: ["tag"],
        },
      },
      {
        name: "context-summary",
        description: "Get a summary of contexts for a specific date",
        inputSchema: {
          type: "object",
          properties: {
            date: {
              type: "string",
              description: "Date to summarize",
              default: "today",
            },
          },
        },
      },
      {
        name: "enrich-activities",
        description: "Enrich ActivityWatch events with context annotations",
        inputSchema: {
          type: "object",
          properties: {
            date: {
              type: "string",
              description: "Date to enrich",
              default: "today",
            },
            start: {
              type: "string",
              description: "Start time for enrichment",
            },
            end: {
              type: "string",
              description: "End time for enrichment",
            },
            window: {
              type: "number",
              description: "Context window in minutes",
            },
          },
        },
      },
    ],
  };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (!checkAwContextInstalled()) {
    throw new Error("aw-context CLI is not installed. Please install it first.");
  }

  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "add-context": {
        const { context, tags } = AddContextSchema.parse(args);
        const tagArgs = tags && tags.length > 0 ? ["--tags", tags.join(",")] : [];
        const result = executeAwContext(["add", context, ...tagArgs]);
        
        return {
          content: [
            {
              type: "text",
              text: result,
            },
          ],
        };
      }

      case "query-contexts": {
        const { date, start, end } = QueryContextSchema.parse(args);
        const cmdArgs = ["query"];
        
        if (start && end) {
          cmdArgs.push("--start", start, "--end", end);
        } else {
          cmdArgs.push(date);
        }
        
        const result = executeAwContext(cmdArgs);
        const contexts = parseContextList(result);
        
        return {
          content: [
            {
              type: "text",
              text: contexts.length > 0 
                ? JSON.stringify(contexts, null, 2)
                : "No contexts found for the specified date range.",
            },
          ],
        };
      }

      case "search-contexts": {
        const { tag } = SearchContextSchema.parse(args);
        const result = executeAwContext(["search", tag]);
        const contexts = parseContextList(result);
        
        return {
          content: [
            {
              type: "text",
              text: contexts.length > 0
                ? JSON.stringify(contexts, null, 2)
                : `No contexts found with tag '${tag}'.`,
            },
          ],
        };
      }

      case "context-summary": {
        const { date } = SummarySchema.parse(args);
        const result = executeAwContext(["summary", "--date", date]);
        
        return {
          content: [
            {
              type: "text",
              text: result || `No summary available for ${date}.`,
            },
          ],
        };
      }

      case "enrich-activities": {
        const { date, start, end, window } = EnrichSchema.parse(args);
        const cmdArgs = ["enrich", date];
        
        if (start) cmdArgs.push("--start", start);
        if (end) cmdArgs.push("--end", end);
        if (window) cmdArgs.push("--window", window.toString());
        
        const result = executeAwContext(cmdArgs);
        const events = parseEnrichedEvents(result);
        
        return {
          content: [
            {
              type: "text",
              text: events.length > 0
                ? JSON.stringify(events, null, 2)
                : "No activities found for the specified time range.",
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error: any) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("ActivityWatch Context MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});