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
    
    @Test("Invalid date format throws error")
    func parseInvalidDate() {
        #expect(throws: ValidationError.self) {
            _ = try parseDate("invalid-date")
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
        let result = try parseDateTimeOrNatural("now")
        let after = Date()
        
        #expect(result >= before)
        #expect(result <= after)
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
    
    @Test("Invalid datetime format throws error")
    func parseInvalidDateTime() {
        #expect(throws: ValidationError.self) {
            _ = try parseDateTimeOrNatural("not-a-date")
        }
    }
}