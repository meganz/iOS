import Foundation

public extension TimeZone {
    /// The Greenwich Mean Time (GMT)
    static var GMT: TimeZone {
        TimeZone(secondsFromGMT: 0)!
    }
}
