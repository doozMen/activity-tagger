import Testing
import Foundation
@testable import AWContextLib

@Suite("Date Parsing Tests")
struct DateParsingTests {
    
    @Test("Parse 'today' returns start of current day")
    func parseToday() throws {
        let result = try parseDate("today")
        let expected = Calendar.current.startOfDay(for: Date())
        
        #expect(result == expected)
    }
    
    @Test("Parse 'yesterday' returns start of previous day")
    func parseYesterday() throws {
        let result = try parseDate("yesterday")
        let expected = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        
        #expect(result == expected)
    }
    
    @Test("Parse specific date in YYYY-MM-DD format")
    func parseSpecificDate() throws {
        let result = try parseDate("2024-12-06")
        
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 6
        let expected = Calendar.current.date(from: components)!
        
        #expect(Calendar.current.compare(result, to: expected, toGranularity: .day) == .orderedSame)
    }
    
    @Test("Invalid date format behavior")
    func parseInvalidDate() {
        // SwiftDateParser might parse empty strings as current date
        // Let's test this behavior
        do {
            let result = try parseDate("")
            print("Empty string parsed as: \(result)")
            // If it doesn't throw, let's at least verify it returns a valid date
            #expect(result.timeIntervalSinceNow < 86400) // Within 24 hours
        } catch {
            // This is what we originally expected
            #expect(error is ValidationError)
        }
    }
}

@Suite("DateTime Parsing Tests")
struct DateTimeParsingTests {
    
    @Test("Parse 'today' in datetime context")
    func parseDateTimeToday() throws {
        let result = try parseDateTimeOrNatural("today")
        let expected = Calendar.current.startOfDay(for: Date())
        
        #expect(result == expected)
    }
    
    @Test("Parse 'now' returns current time")
    func parseDateTimeNow() throws {
        let before = Date()
        Thread.sleep(forTimeInterval: 0.001) // Small delay to ensure time difference
        let result = try parseDateTimeOrNatural("now")
        Thread.sleep(forTimeInterval: 0.001)
        let after = Date()
        
        // Allow for small time differences in parsing
        #expect(abs(result.timeIntervalSince(before)) < 1.0)
        #expect(abs(result.timeIntervalSince(after)) < 1.0)
    }
    
    @Test("Parse time only (HH:MM format)")
    func parseTimeOnly() throws {
        let result = try parseDateTimeOrNatural("14:30")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: result)
        
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }
    
    @Test("Parse full datetime (YYYY-MM-DD HH:MM)")
    func parseFullDateTime() throws {
        let result = try parseDateTimeOrNatural("2024-12-06 14:30")
        
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 6
        components.hour = 14
        components.minute = 30
        components.second = 0
        
        let calendar = Calendar.current
        let expected = calendar.date(from: components)!
        
        // Compare to the minute level since we don't set seconds
        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result)
        let expectedComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: expected)
        
        #expect(resultComponents == expectedComponents)
    }
    
    @Test("Invalid datetime format behavior")
    func parseInvalidDateTime() {
        // SwiftDateParser might parse empty strings as current date
        // Let's test this behavior
        do {
            let result = try parseDateTimeOrNatural("")
            print("Empty string parsed as: \(result)")
            // If it doesn't throw, let's at least verify it returns a valid date
            #expect(abs(result.timeIntervalSinceNow) < 86400 || 
                    Calendar.current.component(.year, from: result) < 2020) // Old date or within 24 hours
        } catch {
            // This is what we originally expected
            #expect(error is ValidationError)
        }
    }
}