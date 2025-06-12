import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1

class ActivityWatchClient {
    private let httpClient: HTTPClient
    private let baseURL: String
    
    init(baseURL: String = "http://localhost:5600") throws {
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        self.baseURL = baseURL
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    func getBuckets() async throws -> [Bucket] {
        let url = "\(baseURL)/api/0/buckets"
        let request = HTTPClientRequest(url: url)
        
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        let body = try await response.body.collect(upTo: 1024 * 1024) // 1MB max
        
        guard response.status == .ok else {
            throw ActivityWatchError.httpError(status: response.status.code)
        }
        
        let data = Data(buffer: body)
        let bucketDict = try JSONDecoder.awDecoder.decode([String: Bucket].self, from: data)
        return Array(bucketDict.values)
    }
    
    func getEvents(bucketId: String, start: Date, end: Date, limit: Int = 1000) async throws -> [ActivityWatchEvent] {
        let startISO = DateFormatter.iso8601Full.string(from: start)
        let endISO = DateFormatter.iso8601Full.string(from: end)
        
        var components = URLComponents(string: "\(baseURL)/api/0/buckets/\(bucketId)/events")!
        components.queryItems = [
            URLQueryItem(name: "start", value: startISO),
            URLQueryItem(name: "end", value: endISO),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw ActivityWatchError.invalidURL
        }
        
        let request = HTTPClientRequest(url: url.absoluteString)
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        let body = try await response.body.collect(upTo: 10 * 1024 * 1024) // 10MB max
        
        guard response.status == .ok else {
            throw ActivityWatchError.httpError(status: response.status.code)
        }
        
        let data = Data(buffer: body)
        return try JSONDecoder.awDecoder.decode([ActivityWatchEvent].self, from: data)
    }
    
    func query(timeperiods: [String], query: [String]) async throws -> [[ActivityWatchEvent]] {
        let url = "\(baseURL)/api/0/query"
        
        let payload = [
            "timeperiods": timeperiods,
            "query": query
        ] as [String : Any]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        request.body = .bytes(ByteBuffer(data: jsonData))
        
        let response = try await httpClient.execute(request, timeout: .seconds(60))
        let body = try await response.body.collect(upTo: 10 * 1024 * 1024) // 10MB max
        
        guard response.status == .ok else {
            throw ActivityWatchError.httpError(status: response.status.code)
        }
        
        let data = Data(buffer: body)
        return try JSONDecoder.awDecoder.decode([[ActivityWatchEvent]].self, from: data)
    }
    
    func findWindowWatcherBucket() async throws -> String? {
        let buckets = try await getBuckets()
        return buckets.first { $0.type == "currentwindow" }?.id
    }
}

enum ActivityWatchError: LocalizedError {
    case httpError(status: UInt)
    case invalidURL
    case noBucketFound
    
    var errorDescription: String? {
        switch self {
        case .httpError(let status):
            return "HTTP error with status code: \(status)"
        case .invalidURL:
            return "Invalid URL"
        case .noBucketFound:
            return "No window watcher bucket found"
        }
    }
}