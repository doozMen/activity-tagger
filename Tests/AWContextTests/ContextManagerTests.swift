import Testing
import Foundation
@testable import AWContextLib

@Suite("ContextManager Tests")
struct ContextManagerTests {
    
    // Clean up test data before each test
    init() throws {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let testDirectory = homeDirectory.appendingPathComponent(".aw-context")
        
        // Remove any existing test data
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            let files = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
            for file in files where file.lastPathComponent.starts(with: "context-") {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    @Test("Add context creates entry with correct properties")
    func addContext() throws {
        let manager = try ContextManager()
        let context = "Working on unit tests"
        let tags = ["testing", "development"]
        
        let entry = try manager.addContext(context: context, tags: tags)
        
        #expect(entry.context == context)
        #expect(entry.tags == tags)
        #expect(entry.id.isEmpty == false)
        #expect(entry.timestamp.timeIntervalSinceNow < 1) // Should be very recent
    }
    
    @Test("Query by time range returns correct entries")
    func queryByTimeRange() throws {
        let manager = try ContextManager()
        
        // Add a context
        let entry = try manager.addContext(context: "Test context", tags: ["test"])
        
        // Query for today
        let start = Calendar.current.startOfDay(for: Date())
        let end = Date()
        
        let results = try manager.queryByTimeRange(start: start, end: end)
        
        #expect(results.contains { $0.id == entry.id })
    }
    
    @Test("Search by tag returns matching entries")
    func searchByTag() throws {
        let manager = try ContextManager()
        
        // Use unique tags for this test
        let uniqueTag1 = "test-ios-\(UUID().uuidString)"
        let uniqueTag2 = "test-android-\(UUID().uuidString)"
        let uniqueTag3 = "test-testing-\(UUID().uuidString)"
        
        // Add contexts with different tags
        let entry1 = try manager.addContext(context: "Context 1", tags: [uniqueTag1, "development"])
        let entry2 = try manager.addContext(context: "Context 2", tags: [uniqueTag2, "development"])
        let entry3 = try manager.addContext(context: "Context 3", tags: [uniqueTag1, uniqueTag3])
        
        // Search for unique tag
        let results = try manager.searchByTag(uniqueTag1)
        
        #expect(results.count == 2)
        #expect(results.contains { $0.id == entry1.id })
        #expect(results.contains { $0.id == entry3.id })
        #expect(!results.contains { $0.id == entry2.id })
    }
    
    @Test("Find nearest context within window")
    func findNearestContext() throws {
        let manager = try ContextManager()
        
        // Add a context
        let entry = try manager.addContext(context: "Recent context", tags: [])
        
        // Find context within 5 minutes from the entry's timestamp
        let nearContext = try manager.findNearestContext(to: entry.timestamp, within: 5)
        
        #expect(nearContext?.id == entry.id)
    }
    
    @Test("Find nearest context outside window returns nil")
    func findNearestContextOutsideWindow() throws {
        let manager = try ContextManager()
        
        // Add a context
        _ = try manager.addContext(context: "Old context", tags: [])
        
        // Try to find context with 0 minute window (should not find anything)
        let farFutureDate = Date().addingTimeInterval(3600) // 1 hour in future
        let nearContext = try manager.findNearestContext(to: farFutureDate, within: 1)
        
        #expect(nearContext == nil)
    }
    
    @Test("Multiple contexts return closest one")
    func findClosestContext() throws {
        let manager = try ContextManager()
        
        // Add multiple contexts
        _ = try manager.addContext(context: "First context", tags: [])
        Thread.sleep(forTimeInterval: 0.1) // Small delay
        let context2 = try manager.addContext(context: "Second context", tags: [])
        Thread.sleep(forTimeInterval: 0.1) // Small delay
        _ = try manager.addContext(context: "Third context", tags: [])
        
        // Find nearest to the second context's timestamp
        let nearContext = try manager.findNearestContext(to: context2.timestamp, within: 30)
        
        #expect(nearContext?.id == context2.id)
    }
}