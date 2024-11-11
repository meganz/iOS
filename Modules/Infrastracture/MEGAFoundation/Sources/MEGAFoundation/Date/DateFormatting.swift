import Foundation

/// A protocol that provides ability of formatting `Date` object into a readable string. `DateFormatter` is the example who fulfills this responsibility.
///
/// Discussion: Adding this protocol is mean to extract the ability of formatting a `Date` object out of `DateFormatter` and shadow other abilities that a
/// `DateFormatter`. For example, instead of returning `DateFormatter` from a dateFormatterFactory, returning the shadow - `DateFormatting`
/// which end users to alter the formatter while using.
@objc public protocol DateFormatting: Sendable {
    func localisedString(from date: Date) -> String
}

// Make `DateFormatter` conforming to `DateFormatting` protocol
extension DateFormatter: DateFormatting {
    public func localisedString(from date: Date) -> String {
        string(from: date)
    }
}
