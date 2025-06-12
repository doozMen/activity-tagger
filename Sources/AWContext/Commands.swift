import ArgumentParser
import Foundation

extension AWContext {
    struct Add: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Add a new context annotation"
        )
        
        @Argument(help: "The context description")
        var context: String
        
        @Option(name: .long, help: "Comma-separated tags")
        var tags: String?
        
        func run() async throws {
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
    
    struct Query: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Query contexts by date range"
        )
        
        @Option(name: .long, help: "Start date (YYYY-MM-DD or 'today', 'yesterday')")
        var start: String
        
        @Option(name: .long, help: "End date (YYYY-MM-DD or 'today', 'yesterday')")
        var end: String?
        
        func run() async throws {
            let manager = try ContextManager()
            
            let startDate = try parseDate(start)
            let endDate = try parseDate(end ?? start)
            
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
    
    struct Search: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Search contexts by tag"
        )
        
        @Argument(help: "Tag to search for")
        var tag: String
        
        func run() async throws {
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
    
    struct Summary: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Generate work summary with context"
        )
        
        @Option(name: .long, help: "Date to summarize (YYYY-MM-DD or 'today', 'yesterday')")
        var date: String = "today"
        
        func run() async throws {
            let targetDate = try parseDate(date)
            let startOfDay = Calendar.current.startOfDay(for: targetDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let awClient = try ActivityWatchClient()
            let contextManager = try ContextManager()
            
            guard let bucketId = try await awClient.findWindowWatcherBucket() else {
                print("Error: No window watcher bucket found")
                return
            }
            
            let events = try await awClient.getEvents(
                bucketId: bucketId,
                start: startOfDay,
                end: endOfDay
            )
            
            var appSummary: [String: (duration: TimeInterval, contexts: Set<String>)] = [:]
            
            for event in events {
                let app = event.data.app
                let duration = event.duration
                
                if appSummary[app] == nil {
                    appSummary[app] = (duration: 0, contexts: Set())
                }
                
                appSummary[app]!.duration += duration
                
                if let context = try contextManager.findNearestContext(to: event.timestamp) {
                    appSummary[app]!.contexts.insert(context.context)
                }
            }
            
            let sortedApps = appSummary.sorted { $0.value.duration > $1.value.duration }
            
            let dateString = DateFormatter.dayFormat.string(from: targetDate)
            print("Application Summary for \(dateString):")
            print(String(repeating: "━", count: 40))
            
            for (app, data) in sortedApps {
                let minutes = Int(data.duration / 60)
                print("\n\(app): \(minutes) minutes")
                if !data.contexts.isEmpty {
                    print("  Contexts: \(data.contexts.joined(separator: ", "))")
                }
            }
        }
    }
    
    struct Enrich: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Show ActivityWatch events with nearest context"
        )
        
        @Option(name: .long, help: "Start date/time (YYYY-MM-DD, HH:MM, 'today', 'yesterday', or full datetime)")
        var start: String?
        
        @Option(name: .long, help: "End date/time (YYYY-MM-DD, HH:MM, 'today', 'yesterday', or full datetime)")
        var end: String?
        
        @Option(name: .long, help: "Context window in minutes")
        var window: Int = 30
        
        func run() async throws {
            let startDate: Date
            let endDate: Date
            
            if let startStr = start {
                startDate = try parseDateTimeOrNatural(startStr)
            } else {
                // Default to today's start
                startDate = Calendar.current.startOfDay(for: Date())
            }
            
            if let endStr = end {
                endDate = try parseDateTimeOrNatural(endStr)
            } else if start != nil {
                // If start is provided but not end, default to end of that day
                let calendar = Calendar.current
                endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: startDate))!.addingTimeInterval(-1)
            } else {
                // Default to current time
                endDate = Date()
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
}

private func parseDate(_ input: String) throws -> Date {
    switch input.lowercased() {
    case "today":
        return Calendar.current.startOfDay(for: Date())
    case "yesterday":
        return Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
    default:
        guard let date = DateFormatter.dayFormat.date(from: input) else {
            throw ValidationError("Invalid date format. Use YYYY-MM-DD, 'today', or 'yesterday'")
        }
        return date
    }
}

private func parseDateTime(_ input: String) throws -> Date {
    let formats = [
        "yyyy-MM-dd HH:mm",
        "HH:mm"
    ]
    
    for format in formats {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: input) {
            if format == "HH:mm" {
                let calendar = Calendar.current
                let now = Date()
                let components = calendar.dateComponents([.hour, .minute], from: date)
                return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
            }
            return date
        }
    }
    
    throw ValidationError("Invalid date/time format. Use 'HH:MM' or 'YYYY-MM-DD HH:MM'")
}

private func parseDateTimeOrNatural(_ input: String) throws -> Date {
    // First try natural language
    switch input.lowercased() {
    case "today":
        return Calendar.current.startOfDay(for: Date())
    case "yesterday":
        return Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
    case "now":
        return Date()
    default:
        break
    }
    
    // Then try date formats
    if let date = DateFormatter.dayFormat.date(from: input) {
        return date
    }
    
    // Finally try datetime formats
    let formats = [
        "yyyy-MM-dd HH:mm",
        "HH:mm"
    ]
    
    for format in formats {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: input) {
            if format == "HH:mm" {
                let calendar = Calendar.current
                let now = Date()
                let components = calendar.dateComponents([.hour, .minute], from: date)
                return calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: now)!
            }
            return date
        }
    }
    
    throw ValidationError("Invalid date/time format. Use 'today', 'yesterday', 'YYYY-MM-DD', 'HH:MM', or 'YYYY-MM-DD HH:MM'")
}