import Foundation

/// Plain text plus style ranges. No Markdown syntax inside.
/// Offsets are UTF-16 code units, so they match `NSRange` and `UITextView`.
/// "\n" is a soft break and U+2028 a hard break. Both stay inside one block.
///
/// Every init and operation keeps `spans` normalized: sorted, clamped to the text, no empty span,
/// and touching or overlapping spans of one style merged. So two equal texts compare equal.
struct RichText: Sendable {
    private(set) var text: String
    private(set) var spans: [RichSpan]

    init(_ text: String = "", spans: [RichSpan] = []) {
        self.text = text
        self.spans = spans.isEmpty ? [] : Self.normalize(spans, length: text.utf16.count)
    }

    var length: Int { text.utf16.count }

    var isEmpty: Bool { text.isEmpty }
}

struct RichSpan: Hashable, Sendable {
    /// UTF-16 offsets into `RichText.text`. Never empty.
    var range: Range<Int>
    var style: RichSpanStyle
}

enum RichSpanStyle: Hashable, Sendable {
    case bold
    case italic
    /// Saved as `<u>...</u>`. Markdown has no native underline.
    case underline
    case strikethrough
    case code
    case link(RichLink)

    var isLink: Bool {
        if case .link = self { true } else { false }
    }
}

/// A link target as Markdown holds it: the destination as written (escapes and entities decoded) and the title.
struct RichLink: Hashable, Sendable {
    var destination: String
    /// Empty when there is no title.
    var title: String

    init(destination: String, title: String = "") {
        self.destination = destination
        self.title = title
    }
}

// MARK: - Equality

// `String ==` compares Unicode canonical forms: "é" equals "e" + U+0301. Their UTF-16 lengths differ,
// so the span offsets would point at other characters. Rich text compares bytes.
extension RichText: Hashable {
    static func == (lhs: RichText, rhs: RichText) -> Bool {
        lhs.spans == rhs.spans && lhs.text.hasSameBytes(as: rhs.text)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(spans)
        hasher.combine(text.utf8.count)
        text.utf8.withContiguousStorageIfAvailable { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
            ?? text.utf8.forEach { hasher.combine($0) }
    }
}

// MARK: - Normalizing

extension RichSpanStyle {
    /// Fixed order for sorting. Links sort by target so two different links have a stable order.
    fileprivate func sortsBefore(_ other: RichSpanStyle) -> Bool {
        if rank != other.rank { return rank < other.rank }
        guard case .link(let lhs) = self, case .link(let rhs) = other else { return false }
        if lhs.destination != rhs.destination { return lhs.destination < rhs.destination }
        return lhs.title < rhs.title
    }

    /// Nesting order of Markdown markers, outer first.
    var rank: Int {
        switch self {
        case .link: 0
        case .bold: 1
        case .italic: 2
        case .strikethrough: 3
        case .underline: 4
        case .code: 5
        }
    }
}

extension RichText {
    /// Already normalized spans pass a linear check and are kept as they are. Typing hits this path.
    static func normalize(_ spans: [RichSpan], length: Int) -> [RichSpan] {
        if isNormalized(spans, length: length) { return spans }
        var byStyle: [RichSpanStyle: [Range<Int>]] = [:]
        for span in spans {
            let lower = max(0, min(span.range.lowerBound, length))
            let upper = max(0, min(span.range.upperBound, length))
            guard lower < upper else { continue }
            byStyle[span.style, default: []].append(lower..<upper)
        }
        var result: [RichSpan] = []
        result.reserveCapacity(spans.count)
        for (style, ranges) in byStyle {
            var merged: [Range<Int>] = []
            for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
                if let last = merged.last, range.lowerBound <= last.upperBound {
                    merged[merged.count - 1] = last.lowerBound..<max(last.upperBound, range.upperBound)
                } else {
                    merged.append(range)
                }
            }
            result += merged.map { RichSpan(range: $0, style: style) }
        }
        result.sort(by: spanSortsBefore)
        return result
    }

    private static func spanSortsBefore(_ lhs: RichSpan, _ rhs: RichSpan) -> Bool {
        if lhs.range.lowerBound != rhs.range.lowerBound { return lhs.range.lowerBound < rhs.range.lowerBound }
        if lhs.style != rhs.style { return lhs.style.sortsBefore(rhs.style) }
        return lhs.range.upperBound < rhs.range.upperBound
    }

    private static func isNormalized(_ spans: [RichSpan], length: Int) -> Bool {
        var lastEnd: [RichSpanStyle: Int] = [:]
        for (index, span) in spans.enumerated() {
            guard span.range.lowerBound >= 0, span.range.upperBound <= length, !span.range.isEmpty else { return false }
            if index > 0, !spanSortsBefore(spans[index - 1], span) { return false }
            if let end = lastEnd[span.style], end >= span.range.lowerBound { return false }
            lastEnd[span.style] = span.range.upperBound
        }
        return true
    }
}

// MARK: - Text pieces

extension RichText {
    /// The part of the text in `range`, with spans clipped and shifted. The range is clamped.
    func slice(_ range: Range<Int>) -> RichText {
        let lower = text.alignedUTF16Offset(range.lowerBound)
        let upper = max(lower, text.alignedUTF16Offset(range.upperBound))
        if lower == 0, upper == length { return self }
        let piece = text.substring(utf16: lower..<upper)
        let clipped = spans.compactMap { span -> RichSpan? in
            let start = max(span.range.lowerBound, lower)
            let end = min(span.range.upperBound, upper)
            guard start < end else { return nil }
            return RichSpan(range: (start - lower)..<(end - lower), style: span.style)
        }
        return RichText(piece, spans: clipped)
    }

    static func + (lhs: RichText, rhs: RichText) -> RichText {
        if rhs.isEmpty { return lhs }
        if lhs.isEmpty { return rhs }
        let shift = lhs.length
        let moved = rhs.spans.map { RichSpan(range: ($0.range.lowerBound + shift)..<($0.range.upperBound + shift), style: $0.style) }
        return RichText(lhs.text + rhs.text, spans: lhs.spans + moved)
    }

    /// Replaces a UTF-16 range with plain text. Spans move with `RichSpanAdjuster`.
    /// With `typingStyles`, the inserted text gets exactly those styles. Without, it joins the spans the edit sits inside.
    func replacing(_ range: Range<Int>, with string: String, typingStyles: Set<RichSpanStyle>? = nil) -> RichText {
        let lower = text.alignedUTF16Offset(range.lowerBound)
        let upper = max(lower, text.alignedUTF16Offset(range.upperBound))
        var newText = text
        newText.replaceUTF16(lower..<upper, with: string)
        let adjusted = RichSpanAdjuster.adjust(
            spans,
            editRange: lower..<upper,
            replacementLength: string.utf16.count,
            typingStyles: typingStyles
        )
        return RichText(newText, spans: adjusted)
    }

    /// Same text with other spans.
    func withSpans(_ newSpans: [RichSpan]) -> RichText {
        RichText(text, spans: newSpans)
    }
}

// MARK: - UTF-16 offsets

extension String {
    /// The index at a UTF-16 offset, clamped to the text. An offset inside a surrogate pair moves to the pair's start.
    func index(utf16Offset offset: Int) -> String.Index {
        let clamped = max(0, min(offset, utf16.count))
        let index = utf16.index(startIndex, offsetBy: clamped)
        if index.samePosition(in: unicodeScalars) == nil {
            return utf16.index(before: index)
        }
        return index
    }

    /// The text between two UTF-16 offsets. It works on scalars: `String` subscripts move an index
    /// to a Character boundary, which would cut a combining mark off its letter at a different place.
    func substring(utf16 range: Range<Int>) -> String {
        let lower = index(utf16Offset: range.lowerBound)
        let upper = Swift.max(lower, index(utf16Offset: range.upperBound))
        return String(unicodeScalars[lower..<upper])
    }

    /// Replaces the text between two UTF-16 offsets, on scalars like `substring(utf16:)`.
    mutating func replaceUTF16(_ range: Range<Int>, with string: String) {
        let lower = index(utf16Offset: range.lowerBound)
        let upper = Swift.max(lower, index(utf16Offset: range.upperBound))
        unicodeScalars.replaceSubrange(lower..<upper, with: string.unicodeScalars)
    }

    /// `offset` clamped to the text and moved off the middle of a surrogate pair.
    func alignedUTF16Offset(_ offset: Int) -> Int {
        let clamped = max(0, min(offset, utf16.count))
        let index = utf16.index(startIndex, offsetBy: clamped)
        return index.samePosition(in: unicodeScalars) == nil ? clamped - 1 : clamped
    }
}
