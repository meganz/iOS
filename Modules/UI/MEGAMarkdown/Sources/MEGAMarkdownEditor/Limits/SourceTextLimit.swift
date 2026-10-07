import Foundation

/// What the source editor can show for a text.
/// TextKit lays out one line as one unit, so every key in a very long line stalls (0.8 s at 5 MB).
enum SourceTextLimit: Equatable, Sendable {
    case editable
    /// A line is longer than `maxLineLength`. No text view is made.
    case lineTooLong
    /// The text is over `maxBytes`.
    case fileTooLarge

    /// 100 MiB of UTF-8.
    static let maxBytes = 100 * 1024 * 1024
    /// In UTF-16 units, like `NSString`. A key in a 100k line takes about 20-30 ms on the simulator.
    static let maxLineLength = 100_000

    /// Reads the whole text. Call it off the main thread: it takes tens of ms at 100 MB.
    static func check(_ text: String) -> SourceTextLimit {
        if text.utf8.count > maxBytes {
            return .fileTooLarge
        }
        let hasLongLine = text.utf8.withContiguousStorageIfAvailable { hasLineLonger(than: maxLineLength, in: $0) }
            ?? hasLineLonger(than: maxLineLength, in: text.utf8)
        return hasLongLine ? .lineTooLong : .editable
    }

    /// Counts UTF-16 units per line from UTF-8 bytes. A 4-byte character is 2 units. Stops at the first long line.
    static func hasLineLonger(than limit: Int, in bytes: some Sequence<UInt8>) -> Bool {
        var length = 0
        for byte in bytes {
            if byte == 10 || byte == 13 {
                length = 0
            } else if byte & 0xC0 != 0x80 {
                length += byte >= 0xF0 ? 2 : 1
                if length > limit {
                    return true
                }
            }
        }
        return false
    }
}
