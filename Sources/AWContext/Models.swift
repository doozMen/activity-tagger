import Foundation

struct ContextEntry: Codable {
    let id: String
    let timestamp: Date
    let context: String
    let tags: [String]
    
    init(context: String, tags: [String] = []) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.context = context
        self.tags = tags
    }
}

struct ActivityWatchEvent: Codable {
    let id: Int?
    let timestamp: Date
    let duration: Double
    let data: EventData
}

struct EventData: Codable {
    let app: String
    let title: String
}

struct Bucket: Codable {
    let id: String
    let name: String
    let type: String
    let client: String
    let hostname: String
    let created: Date
}

struct QueryResult: Codable {
    let events: [ActivityWatchEvent]
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
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
}

extension JSONEncoder {
    static let awEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatter.iso8601Full.string(from: date))
        }
        return encoder
    }()
}

extension JSONDecoder {
    static let awDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = DateFormatter.iso8601Full.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        return decoder
    }()
}