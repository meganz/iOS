import Foundation
// Only for the underline attribute key. No views here.
import SwiftUI

/// Style bits of one inline run. Same meaning as the Foundation `InlinePresentationIntent` bits we use.
struct InlineStyle: OptionSet, Hashable, Sendable {
    let rawValue: UInt16

    static let emphasized = InlineStyle(rawValue: 1 << 0)
    static let stronglyEmphasized = InlineStyle(rawValue: 1 << 1)
    static let strikethrough = InlineStyle(rawValue: 1 << 2)
    static let code = InlineStyle(rawValue: 1 << 3)
    static let softBreak = InlineStyle(rawValue: 1 << 4)
    static let lineBreak = InlineStyle(rawValue: 1 << 5)
    static let inlineHTML = InlineStyle(rawValue: 1 << 6)
    static let blockHTML = InlineStyle(rawValue: 1 << 7)
    static let underline = InlineStyle(rawValue: 1 << 8)
    /// The run's link is an image URL, not a link.
    static let image = InlineStyle(rawValue: 1 << 9)
    /// A U+FFFC the parser added for an empty link or alt text. It keeps the block alive and is not author text.
    static let placeholder = InlineStyle(rawValue: 1 << 10)
}

/// A link or image target as written in the source.
struct InlineLink: Equatable, Sendable {
    var url: String
    /// The optional title, like `[a](url "title")`. Empty when there is none.
    var title: String

    /// cmark gives a destination with escapes and entities decoded. `URL(string:)` turns `%20` into `%2520`
    /// when the path also has a non-ASCII character or a `[`. So every byte outside RFC 3986 and outside the host is encoded first.
    static func makeURL(_ destination: String, relativeTo baseURL: URL?) -> URL? {
        if let url = makeURL(destination, relativeTo: baseURL, encodesHostASCII: false) { return url }
        // Foundation rejects some ASCII in a host, like "`". cmark encodes it, so the link keeps working.
        return makeURL(destination, relativeTo: baseURL, encodesHostASCII: true)
    }

    private static func makeURL(_ destination: String, relativeTo baseURL: URL?, encodesHostASCII: Bool) -> URL? {
        let bytes = Array(destination.utf8)
        let host = hostRange(bytes)
        var encoded: [UInt8] = []
        encoded.reserveCapacity(bytes.count)
        for (index, byte) in bytes.enumerated() {
            // The host stays as written. Foundation turns a non-ASCII host into punycode and keeps `[::1]`.
            let isInHost = host.contains(index) && !(encodesHostASCII && byte < 0x80)
            // A `%` that already starts an escape stays. A lone `%` is encoded.
            let isEscape = byte == UInt8(ascii: "%") && index + 2 < bytes.count && isHexDigit(bytes[index + 1]) && isHexDigit(bytes[index + 2])
            // RFC 3986 allows `[` and `]` only around an IPv6 host.
            let isBracket = byte == UInt8(ascii: "[") || byte == UInt8(ascii: "]")
            if isInHost || isEscape || (allowedInURL(byte) && !isBracket) {
                encoded.append(byte)
            } else {
                encoded += Array(String(format: "%%%02X", byte).utf8)
            }
        }
        var text = String(decoding: encoded, as: UTF8.self)
        // RFC 3986 section 4.2: a relative path with `:` in its first segment needs `./`, or `foo):` reads as a scheme.
        let firstSegment = text.prefix { $0 != "/" && $0 != "?" && $0 != "#" }
        if let colon = firstSegment.firstIndex(of: ":"), !isScheme(firstSegment[..<colon]) {
            text = "./" + text
        }
        return URL(string: text, relativeTo: baseURL)
    }

    /// RFC 3986 unreserved and reserved characters.
    private static func allowedInURL(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "A")...UInt8(ascii: "Z"), UInt8(ascii: "0")...UInt8(ascii: "9"):
            return true
        default:
            return "-._~:/?#[]@!$&'()*+,;=".utf8.contains(byte)
        }
    }

    /// The bytes after `scheme://` or a leading `//` up to the next `/`, `?` or `#`. Empty when there is no `//`.
    private static func hostRange(_ bytes: [UInt8]) -> Range<Int> {
        let slash = UInt8(ascii: "/")
        let isDelimiter = { (byte: UInt8) in byte == slash || byte == UInt8(ascii: "?") || byte == UInt8(ascii: "#") }
        // The scheme ends at the first `:` before any delimiter. `//host` has no scheme and takes the base URL's.
        let schemeEnd = bytes.prefix { !isDelimiter($0) }.firstIndex(of: UInt8(ascii: ":")).map { $0 + 1 } ?? 0
        guard schemeEnd + 1 < bytes.count, bytes[schemeEnd] == slash, bytes[schemeEnd + 1] == slash,
              schemeEnd == 0 || isScheme(Substring(decoding: bytes[..<(schemeEnd - 1)], as: UTF8.self)) else { return 0..<0 }
        let start = schemeEnd + 2
        let end = bytes[start...].firstIndex(where: isDelimiter) ?? bytes.count
        return start..<end
    }

    private static func isHexDigit(_ byte: UInt8) -> Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
            || (UInt8(ascii: "a")...UInt8(ascii: "f")).contains(byte)
            || (UInt8(ascii: "A")...UInt8(ascii: "F")).contains(byte)
    }

    /// RFC 3986 scheme: a letter, then letters, digits, `+`, `-` or `.`.
    private static func isScheme(_ text: Substring) -> Bool {
        guard let first = text.first, first.isASCII, first.isLetter else { return false }
        return text.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "+" || $0 == "-" || $0 == ".") }
    }
}

/// One run of `InlineText`. It starts where the run before it ends. Stored small: big files have millions.
struct InlineRun: Equatable, Sendable {
    private var storedEnd: Int32
    var style: InlineStyle
    private var storedLink: Int32

    init(end: Int, style: InlineStyle, link: Int) {
        storedEnd = Int32(clamping: end)
        self.style = style
        storedLink = Int32(clamping: link)
    }

    /// UTF-8 offset in `InlineText.text` where this run ends.
    var end: Int {
        get { Int(storedEnd) }
        set { storedEnd = Int32(clamping: newValue) }
    }

    /// Index in `InlineText.links`, or -1.
    var link: Int { Int(storedLink) }
}

/// The text of one leaf block in a cheap form: a plain String plus style runs.
/// It becomes `AttributedString` only when needed (the preview does it for visible rows only).
package struct InlineText: Equatable, Sendable {
    private(set) var text = ""
    /// Empty when the whole text is one plain run. That saves an array for most table cells and list items.
    private(set) var styledRuns: [InlineRun] = []
    /// Link and image targets. URLs are resolved against the base URL on conversion.
    let links: [InlineLink]

    init(links: [InlineLink] = []) {
        self.links = links
    }

    var isEmpty: Bool { text.isEmpty }

    /// All runs, with the plain run filled in.
    var runs: [InlineRun] {
        guard styledRuns.isEmpty, !text.isEmpty else { return styledRuns }
        return [InlineRun(end: text.utf8.count, style: [], link: -1)]
    }

    mutating func reserveCapacity(bytes: Int, runs count: Int) {
        text.reserveCapacity(bytes)
        if count > 0 { styledRuns.reserveCapacity(count) }
    }

    mutating func append(_ piece: String, style: InlineStyle, link: Int = -1) {
        guard !piece.isEmpty else { return }
        let isPlain = style.isEmpty && link < 0
        if styledRuns.isEmpty && isPlain {
            text += piece
            return
        }
        if styledRuns.isEmpty && !text.isEmpty {
            // The plain text so far becomes a real run, because a styled one follows.
            styledRuns.append(InlineRun(end: text.utf8.count, style: [], link: -1))
        }
        text += piece
        let end = text.utf8.count
        if let last = styledRuns.last, last.style == style, last.link == link {
            styledRuns[styledRuns.count - 1].end = end
        } else {
            styledRuns.append(InlineRun(end: end, style: style, link: link))
        }
    }

    func attributed(baseURL: URL?) -> AttributedString {
        var result = AttributedString()
        var urls: [Int: URL?] = [:]
        var start = text.utf8.startIndex
        for run in runs {
            let end = text.utf8.index(text.utf8.startIndex, offsetBy: run.end)
            var piece = AttributedString(String(text[start..<end]))
            start = end
            let intent = Self.intent(run.style)
            if !intent.isEmpty { piece.inlinePresentationIntent = intent }
            if run.style.contains(.underline) {
                piece[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
            }
            if run.link >= 0 {
                let url: URL?
                if let cached = urls[run.link] {
                    url = cached
                } else {
                    url = InlineLink.makeURL(links[run.link].url, relativeTo: baseURL)
                    urls[run.link] = url
                }
                if let url {
                    if run.style.contains(.image) { piece.imageURL = url } else { piece.link = url }
                }
                // Foundation keeps the title as the alternate description.
                let title = links[run.link].title
                if !title.isEmpty { piece.alternateDescription = title }
            }
            result += piece
        }
        return result
    }

    private static func intent(_ style: InlineStyle) -> InlinePresentationIntent {
        var intent: InlinePresentationIntent = []
        if style.contains(.emphasized) { intent.insert(.emphasized) }
        if style.contains(.stronglyEmphasized) { intent.insert(.stronglyEmphasized) }
        if style.contains(.strikethrough) { intent.insert(.strikethrough) }
        if style.contains(.code) { intent.insert(.code) }
        if style.contains(.softBreak) { intent.insert(.softBreak) }
        if style.contains(.lineBreak) { intent.insert(.lineBreak) }
        if style.contains(.inlineHTML) { intent.insert(.inlineHTML) }
        if style.contains(.blockHTML) { intent.insert(.blockHTML) }
        return intent
    }

    /// The part between two UTF-8 offsets. Both must sit on character boundaries.
    func slice(_ range: Range<Int>) -> InlineText {
        var result = InlineText(links: links)
        let utf8 = text.utf8
        var runStart = 0
        for run in runs {
            let lower = max(runStart, range.lowerBound)
            let upper = min(run.end, range.upperBound)
            if lower < upper {
                let from = utf8.index(utf8.startIndex, offsetBy: lower)
                let to = utf8.index(utf8.startIndex, offsetBy: upper)
                result.append(String(text[from..<to]), style: run.style, link: run.link)
            }
            runStart = run.end
            if runStart >= range.upperBound { break }
        }
        return result
    }

    /// Removes the first `count` UTF-8 bytes. They must end on a character boundary.
    mutating func dropFirstBytes(_ count: Int) {
        self = slice(count..<text.utf8.count)
    }
}
