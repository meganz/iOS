import Foundation

/// Escapes plain text, link destinations and titles, so they parse back as the same text.
enum MarkdownTextEscaper {
    /// Characters that start inline syntax anywhere in a line.
    private static let inlineSyntax: Set<Unicode.Scalar> = ["\\", "`", "*", "_", "[", "]", "<", "|", "~"]
    /// Characters that start block syntax at a line start: heading, quote, list, setext underline.
    private static let lineStartSyntax: Set<Unicode.Scalar> = ["#", ">", "+", "-", "="]

    /// `atLineStart` is true when `text` starts a line. It is false after the call.
    /// It works on scalars: cmark reads bytes, so `>` followed by a combining mark still starts a quote.
    static func escape(_ text: String, atLineStart: inout Bool, isATXHeading: Bool) -> String {
        let scalars = Array(text.unicodeScalars)
        var output = String.UnicodeScalarView()
        var index = 0
        if atLineStart, let first = scalars.first {
            atLineStart = false
            if lineStartSyntax.contains(first) {
                output.append("\\")
                output.append(first)
                index = 1
            } else if let delimiter = orderedListDelimiter(in: scalars) {
                // `12. x` or `12) x` would start an ordered list: escape the delimiter.
                output.append(contentsOf: scalars[..<delimiter])
                output.append("\\")
                index = delimiter
            }
        }
        while index < scalars.count {
            if needsEscape(scalars, at: index, isATXHeading: isATXHeading) {
                output.append("\\")
            }
            output.append(scalars[index])
            index += 1
        }
        return String(output)
    }

    private static func needsEscape(_ scalars: [Unicode.Scalar], at index: Int, isATXHeading: Bool) -> Bool {
        let scalar = scalars[index]
        let next = index + 1 < scalars.count ? scalars[index + 1] : nil
        if inlineSyntax.contains(scalar) || (isATXHeading && scalar == "#") {
            return true
        }
        if scalar == "&", let next, next == "#" || isASCIIAlphanumeric(next) {
            return true
        }
        // The piece may end right before a link: `![` would start an image.
        if scalar == "!", next == nil {
            return true
        }
        // GFM turns `scheme://` and `www.` into links. The escapes keep them plain text.
        // A plain `name@host` cannot be kept: cmark joins text nodes before it looks for email addresses.
        if scalar == ":", next == "/", index + 2 < scalars.count, scalars[index + 2] == "/",
           index > 0, isASCIIAlphanumeric(scalars[index - 1]) {
            return true
        }
        if scalar == ".", index >= 3, String(String.UnicodeScalarView(scalars[(index - 3)..<index])).lowercased() == "www",
           index == 3 || !isASCIIAlphanumeric(scalars[index - 4]) {
            return true
        }
        return false
    }

    private static func isASCIIAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII && (scalar.properties.isAlphabetic || ("0"..."9").contains(scalar))
    }

    /// Index of the `.` or `)` after leading digits, when it would start an ordered list item.
    private static func orderedListDelimiter(in scalars: [Unicode.Scalar]) -> Int? {
        var end = 0
        while end < scalars.count, ("0"..."9").contains(scalars[end]) { end += 1 }
        guard end > 0, end < scalars.count, scalars[end] == "." || scalars[end] == ")" else { return nil }
        let after = end + 1 < scalars.count ? scalars[end + 1] : nil
        return after == nil || after == " " || after == "\t" ? end : nil
    }

    // MARK: - Links

    /// A link destination. `<...>` when it has a space or a control character, bare otherwise.
    static func destination(_ destination: String) -> String {
        if destination.isEmpty { return "<>" }
        let scalars = Array(destination.unicodeScalars)
        let needsBrackets = scalars.contains { $0 == " " || $0.value < 0x20 || $0.value == 0x7F }
        var output = String.UnicodeScalarView()
        if needsBrackets { output.append("<") }
        for (index, scalar) in scalars.enumerated() {
            if scalar == "\\" || scalar == "<" || scalar == ">" || (!needsBrackets && (scalar == "(" || scalar == ")")) {
                output.append("\\")
                output.append(scalar)
            } else if startsEntity(scalars, at: index) {
                // cmark decodes entities before backslash escapes here, so `\&` would not stop `&copy;`.
                output.append(contentsOf: "&amp;".unicodeScalars)
            } else {
                output.append(scalar)
            }
        }
        if needsBrackets { output.append(">") }
        return String(output)
    }

    /// ` "title"`, or "" for no title.
    static func title(_ title: String) -> String {
        guard !title.isEmpty else { return "" }
        let scalars = Array(title.unicodeScalars)
        var output = String.UnicodeScalarView(" \"".unicodeScalars)
        for (index, scalar) in scalars.enumerated() {
            if scalar == "\\" || scalar == "\"" {
                output.append("\\")
                output.append(scalar)
            } else if startsEntity(scalars, at: index) {
                output.append(contentsOf: "&amp;".unicodeScalars)
            } else {
                output.append(scalar)
            }
        }
        output.append("\"")
        return String(output)
    }

    /// An `&` that cmark could read as the start of an entity (`&copy;`, `&#35;`).
    private static func startsEntity(_ scalars: [Unicode.Scalar], at index: Int) -> Bool {
        guard scalars[index] == "&", index + 1 < scalars.count else { return false }
        return scalars[index + 1] == "#" || isASCIIAlphanumeric(scalars[index + 1])
    }

    /// `<url>` or `<name@host>` when cmark reads it back as a link with exactly this text and destination.
    /// Autolinks keep backslashes and decode entities, so only plain URL characters qualify.
    static func autolink(text: String, destination: String) -> String? {
        if text == destination, isAutolinkURI(destination) {
            return "<\(destination)>"
        }
        if destination == "mailto:" + text, isAutolinkEmail(text) {
            return "<\(text)>"
        }
        return nil
    }

    private static let uriCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~:/?#[]@!$'()*+,;=%")

    private static func isAutolinkURI(_ text: String) -> Bool {
        guard let colon = text.firstIndex(of: ":") else { return false }
        let scheme = text[..<colon]
        guard (2...32).contains(scheme.count), let first = scheme.first, first.isASCII, first.isLetter,
              scheme.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "+" || $0 == "." || $0 == "-") }) else { return false }
        return text.unicodeScalars.allSatisfy { uriCharacters.contains($0) }
    }

    private static func isAutolinkEmail(_ text: String) -> Bool {
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return false }
        let local = parts[0].allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || ".!#$%'*+/=?^_`{|}~-".contains($0)) }
        let labels = parts[1].split(separator: ".", omittingEmptySubsequences: false)
        let host = labels.allSatisfy { label in
            !label.isEmpty && label.count <= 63 && label.first != "-" && label.last != "-"
                && label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        }
        return local && host
    }
}
