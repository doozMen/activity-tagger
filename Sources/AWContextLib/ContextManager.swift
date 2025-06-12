import Foundation

public class ContextManager {
    private let baseDirectory: URL
    
    public init() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.baseDirectory = homeDirectory.appendingPathComponent(".aw-context")
        
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }
    
    public func addContext(context: String, tags: [String] = []) throws -> ContextEntry {
        let entry = ContextEntry(context: context, tags: tags)
        let date = Date()
        
        var entries = try loadContext(for: date)
        entries.append(entry)
        try saveContext(entries, for: date)
        
        return entry
    }
    
    public func queryByTimeRange(start: Date, end: Date) throws -> [ContextEntry] {
        var allEntries: [ContextEntry] = []
        
        var currentDate = start
        let calendar = Calendar.current
        
        while currentDate <= end {
            do {
                let entries = try loadContext(for: currentDate)
                let filtered = entries.filter { entry in
                    entry.timestamp >= start && entry.timestamp <= end
                }
                allEntries.append(contentsOf: filtered)
            } catch {
                // File might not exist for this date, which is ok
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return allEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    public func searchByTag(_ tag: String) throws -> [ContextEntry] {
        var matchingEntries: [ContextEntry] = []
        
        let files = try FileManager.default.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil
        )
        
        for file in files where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let entries = try JSONDecoder.awDecoder.decode([ContextEntry].self, from: data)
                let filtered = entries.filter { $0.tags.contains(tag) }
                matchingEntries.append(contentsOf: filtered)
            } catch {
                // Skip files that can't be decoded
            }
        }
        
        return matchingEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    func loadContext(for date: Date) throws -> [ContextEntry] {
        let filename = contextFilename(for: date)
        let fileURL = baseDirectory.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.awDecoder.decode([ContextEntry].self, from: data)
    }
    
    func saveContext(_ entries: [ContextEntry], for date: Date) throws {
        let filename = contextFilename(for: date)
        let fileURL = baseDirectory.appendingPathComponent(filename)
        
        let data = try JSONEncoder.awEncoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
    
    private func contextFilename(for date: Date) -> String {
        let dateString = DateFormatter.dayFormat.string(from: date)
        return "context-\(dateString).json"
    }
    
    public func findNearestContext(to date: Date, within windowMinutes: Int = 30) throws -> ContextEntry? {
        let window = TimeInterval(windowMinutes * 60)
        let start = date.addingTimeInterval(-window)
        let end = date.addingTimeInterval(window)
        
        let contexts = try queryByTimeRange(start: start, end: end)
        
        return contexts.min { context1, context2 in
            abs(context1.timestamp.timeIntervalSince(date)) < abs(context2.timestamp.timeIntervalSince(date))
        }
    }
}