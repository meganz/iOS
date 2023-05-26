import Foundation

public enum DateFormattingError: Error {
    case invalidISO8601DateFormat
}

public extension String {
    var date: Date {
        get throws {
            guard let date = ISO8601DateFormatter().date(from: self) else {
                throw DateFormattingError.invalidISO8601DateFormat
            }
            
            return date
        }
    }
}
