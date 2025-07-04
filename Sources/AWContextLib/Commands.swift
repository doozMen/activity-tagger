import ArgumentParser
import Foundation
import SwiftDateParser

public struct ValidationError: LocalizedError {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
    
    public var errorDescription: String? {
        return message
    }
}

public struct Add: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Add a new context annotation"
    )
    
    @Argument(help: "The context description")
    public var context: String
    
    @Option(name: .long, help: "Comma-separated tags")
    public var tags: String?
    
    public init() {}
    
    public func run() async throws {
        let manager = try ContextManager()
        let tagList = tags?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []
        
        let entry = try manager.addContext(context: context, tags: tagList)
        
        print("✓ Context added at \(DateFormatter.iso8601Full.string(from: entry.timestamp))")
        print("  ID: \(entry.id)")
        if !tagList.isEmpty {
            print("  Tags: \(tagList.joined(separator: ", "))")
        }
    }
}

public struct Query: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Query contexts by date range",
        discussion: "Query contexts for a specific date or date range. Examples:\n  aw-context query today\n  aw-context query yesterday\n  aw-context query 2024-12-06\n  aw-context query today --end tomorrow"
    )
    
    @Argument(help: "Date to query (YYYY-MM-DD, 'today', 'yesterday')")
    public var date: String = "today"
    
    @Option(name: .long, help: "Override start date")
    public var start: String?
    
    @Option(name: .long, help: "End date for range queries")
    public var end: String?
    
    public init() {}
    
    public func run() async throws {
        let manager = try ContextManager()
        
        // Use explicit start if provided, otherwise use positional argument
        let startDate = try parseDate(start ?? date)
        let endDate = try parseDate(end ?? start ?? date)
        
        let entries = try manager.queryByTimeRange(start: startDate, end: endDate)
        
        if entries.isEmpty {
            print("No contexts found in the specified date range.")
            return
        }
        
        print("Found \(entries.count) context(s):")
        print("")
        
        for entry in entries {
            let timeString = DateFormatter.iso8601Full.string(from: entry.timestamp)
            print("\(timeString)")
            print("  \(entry.context)")
            if !entry.tags.isEmpty {
                print("  Tags: \(entry.tags.joined(separator: ", "))")
            }
            print("")
        }
    }
}

public struct Search: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Search contexts by tag"
    )
    
    @Argument(help: "Tag to search for")
    public var tag: String
    
    public init() {}
    
    public func run() async throws {
        let manager = try ContextManager()
        let entries = try manager.searchByTag(tag)
        
        if entries.isEmpty {
            print("No contexts found with tag '\(tag)'.")
            return
        }
        
        print("Found \(entries.count) context(s) with tag '\(tag)':")
        print("")
        
        for entry in entries {
            let timeString = DateFormatter.iso8601Full.string(from: entry.timestamp)
            print("\(timeString)")
            print("  \(entry.context)")
            print("  Tags: \(entry.tags.joined(separator: ", "))")
            print("")
        }
    }
}

public struct Summary: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Generate daily summary with context"
    )
    
    @Option(name: .long, help: "Date to summarize (YYYY-MM-DD or 'today', 'yesterday')")
    public var date: String = "today"
    
    public init() {}
    
    public func run() async throws {
        let targetDate = try parseDate(date)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
        
        let awClient = try ActivityWatchClient()
        let contextManager = try ContextManager()
        
        // Get contexts for the day
        let contexts = try contextManager.queryByTimeRange(start: startOfDay, end: endOfDay)
        
        print("=== Summary for \(DateFormatter.dayFormat.string(from: targetDate)) ===")
        print("")
        
        if contexts.isEmpty {
            print("No contexts recorded for this day.")
        } else {
            print("Contexts (\(contexts.count)):")
            for context in contexts {
                let timeString = DateFormatter.timeFormat.string(from: context.timestamp)
                print("  \(timeString) - \(context.context)")
                if !context.tags.isEmpty {
                    print("         Tags: \(context.tags.joined(separator: ", "))")
                }
            }
        }
        
        // Get activity summary
        do {
            let summary = try await awClient.getDailySummary(date: targetDate)
            
            print("\nTop Applications:")
            let topApps = summary.sorted { $0.value.duration > $1.value.duration }.prefix(10)
            
            for (app, data) in topApps {
                let minutes = Int(data.duration / 60)
                print("\n\(app): \(minutes) minutes")
                if !data.contexts.isEmpty {
                    print("  Contexts: \(data.contexts.joined(separator: ", "))")
                }
            }
        } catch {
            print("\nError fetching activity data: \(error)")
        }
    }
}

public struct Enrich: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Show ActivityWatch events with nearest context",
        discussion: "Enrich ActivityWatch events with context information. Examples:\n  aw-context enrich today\n  aw-context enrich yesterday\n  aw-context enrich 09:00 --end 17:00\n  aw-context enrich 2024-12-06"
    )
    
    @Argument(help: "Date/time to enrich (YYYY-MM-DD, HH:MM, 'today', 'yesterday')")
    public var date: String = "today"
    
    @Option(name: .long, help: "Override start date/time")
    public var start: String?
    
    @Option(name: .long, help: "End date/time")
    public var end: String?
    
    @Option(name: .long, help: "Context window in minutes")
    public var window: Int = 30
    
    public init() {}
    
    public func run() async throws {
        let startDate: Date
        let endDate: Date
        
        // Use explicit start if provided, otherwise use positional argument
        let startStr = start ?? date
        startDate = try parseDateTimeOrNatural(startStr)
        
        if let endStr = end {
            endDate = try parseDateTimeOrNatural(endStr)
        } else {
            // If no end specified, use end of day for date inputs, or current time for time inputs
            if startStr.contains(":") {
                // Time format - assume same day
                endDate = Date()
            } else {
                // Date format - use end of that day
                let calendar = Calendar.current
                endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: startDate))!.addingTimeInterval(-1)
            }
        }
        
        let awClient = try ActivityWatchClient()
        let contextManager = try ContextManager()
        
        guard let bucketId = try await awClient.findWindowWatcherBucket() else {
            print("Error: No window watcher bucket found")
            return
        }
        
        let events = try await awClient.getEvents(
            bucketId: bucketId,
            start: startDate,
            end: endDate
        )
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for event in events {
            let timeString = timeFormatter.string(from: event.timestamp)
            let app = event.data.app
            let title = event.data.title
            
            var output = "\(timeString) | \(app) - \(title)"
            
            if let context = try contextManager.findNearestContext(to: event.timestamp, within: window) {
                output += " | Context: \(context.context)"
            }
            
            print(output)
        }
    }
}

// MARK: - Helper Functions

public func parseDate(_ input: String) throws -> Date {
    do {
        // SwiftDateParser handles natural language like "today", "yesterday", etc.
        let parsedDate = try SwiftDateParser.parse(input)
        
        // For date-only parsing, we want to return the start of day
        return Calendar.current.startOfDay(for: parsedDate)
    } catch {
        // If SwiftDateParser fails, provide a helpful error message
        throw ValidationError("Invalid date format. Try: YYYY-MM-DD, 'today', 'yesterday', '3 days ago', 'next week', etc.")
    }
}

public func parseDateTimeOrNatural(_ input: String) throws -> Date {
    do {
        // SwiftDateParser handles all natural language and various formats
        let parsedDate = try SwiftDateParser.parse(input)
        
        // Special handling for "today" and "yesterday" to ensure we get start of day
        switch input.lowercased() {
        case "today":
            return Calendar.current.startOfDay(for: parsedDate)
        case "yesterday":
            return Calendar.current.startOfDay(for: parsedDate)
        default:
            // For time-only inputs like "14:30", SwiftDateParser will use today's date
            // This matches the original behavior
            return parsedDate
        }
    } catch {
        // If SwiftDateParser fails, provide a helpful error message
        throw ValidationError("Invalid date/time format. Try: 'today', 'yesterday', 'now', '2 hours ago', 'tomorrow at 3pm', 'YYYY-MM-DD', 'HH:MM', etc.")
    }
}

