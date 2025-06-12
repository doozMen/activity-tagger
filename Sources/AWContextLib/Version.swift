import Foundation

public enum AWContextVersion {
    public static let current = "1.1.0"
    public static let buildDate = "2024-12-06"
    
    public static var fullVersion: String {
        return "\(current) (\(buildDate))"
    }
}