import Foundation

public struct ContextEntry: Codable {
    public let id: String
    public let timestamp: Date
    public let context: String
    public let tags: [String]
    
    public init(context: String, tags: [String] = []) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.context = context
        self.tags = tags
    }
}

public struct ActivityWatchEvent: Codable {
    public let id: Int?
    public let timestamp: Date
    public let duration: Double
    public let data: EventData
}

public struct EventData: Codable {
    public let app: String
    public let title: String
}

public struct Bucket: Codable {
    public let id: String
    public let name: String?
    public let type: String
    public let client: String
    public let hostname: String
    public let created: Date
}

public struct QueryResult: Codable {
    public let events: [ActivityWatchEvent]
}

public extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601ActivityWatch: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let dayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let timeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

public extension JSONEncoder {
    static let awEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatter.iso8601Full.string(from: date))
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

public extension JSONDecoder {
    static let awDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats that ActivityWatch might use
            let formatters = [
                DateFormatter.iso8601Full,
                ISO8601DateFormatter(), // Standard ISO8601
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'+00:00'"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    return formatter
                }()
            ]
            
            for formatter in formatters {
                if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                    if let date = iso8601Formatter.date(from: dateString) {
                        return date
                    }
                } else if let dateFormatter = formatter as? DateFormatter {
                    if let date = dateFormatter.date(from: dateString) {
                        return date
                    }
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        return decoder
    }()
}