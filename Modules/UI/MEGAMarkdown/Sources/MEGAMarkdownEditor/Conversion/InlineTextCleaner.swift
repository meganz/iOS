import Foundation

/// Removes what a re-parse drops anyway, so export and re-import agree:
/// spaces and tabs at line edges, empty lines, and breaks at the text edges.
/// Emphasis spans also shrink to their visible part. One pass, linear in the text length.
enum InlineTextCleaner {
    /// `joinsLines`: breaks become spaces (an ATX heading is one line).
    static func cleaned(_ text: RichText, joinsLines: Bool) -> RichText {
        let units = Array(text.text.utf16)
        var keep = [Bool](repeating: false, count: units.count)
        var replaced: [Int: UInt16] = [:]
        // Each line is the part between two breaks. A break stays only between two lines that keep text.
        var lineStart = 0
        var pendingBreak: Int?
        var hasKeptLine = false
        var index = 0
        while index <= units.count {
            let atEnd = index == units.count
            guard atEnd || isBreak(units[index]) else {
                index += 1
                continue
            }
            var lower = lineStart
            var upper = index
            let line = lineStart..<index
            while lower < upper, isSpaceOrTab(units[lower]), !isInsideMarkers(lower, line: line, spans: text.spans) { lower += 1 }
            while upper > lower, isSpaceOrTab(units[upper - 1]), !isInsideMarkers(upper - 1, line: line, spans: text.spans) { upper -= 1 }
            if lower < upper {
                if hasKeptLine, let pendingBreak { keep[pendingBreak] = true }
                for kept in lower..<upper { keep[kept] = true }
                hasKeptLine = true
                pendingBreak = nil
            }
            if !atEnd, hasKeptLine, pendingBreak == nil {
                // The first break after a kept line. Later breaks before the next text are empty lines.
                pendingBreak = index
                if joinsLines { replaced[index] = 32 }
            }
            lineStart = index + 1
            index += 1
        }
        guard keep.contains(false) || !replaced.isEmpty else { return trimmedSpans(codeCutAtBreaks(text)) }

        // `newOffset[i]` is the new offset of old offset `i`.
        var newOffset = [Int](repeating: 0, count: units.count + 1)
        var newUnits: [UInt16] = []
        newUnits.reserveCapacity(units.count)
        for (offset, unit) in units.enumerated() {
            newOffset[offset] = newUnits.count
            if keep[offset] { newUnits.append(replaced[offset] ?? unit) }
        }
        newOffset[units.count] = newUnits.count
        let spans = text.spans.map { RichSpan(range: newOffset[$0.range.lowerBound]..<newOffset[$0.range.upperBound], style: $0.style) }
        return trimmedSpans(codeCutAtBreaks(RichText(String(decoding: newUnits, as: UTF16.self), spans: spans)))
    }

    /// A code span cannot hold a line end, so code on a break is dropped from the break.
    private static func codeCutAtBreaks(_ text: RichText) -> RichText {
        let units = Array(text.text.utf16)
        guard text.spans.contains(where: { $0.style == .code && $0.range.contains { isBreak(units[$0]) } }) else { return text }
        var spans: [RichSpan] = []
        for span in text.spans {
            guard span.style == .code else {
                spans.append(span)
                continue
            }
            var lower = span.range.lowerBound
            for offset in span.range where isBreak(units[offset]) {
                if lower < offset { spans.append(RichSpan(range: lower..<offset, style: .code)) }
                lower = offset + 1
            }
            if lower < span.range.upperBound { spans.append(RichSpan(range: lower..<span.range.upperBound, style: .code)) }
        }
        return text.withSpans(spans)
    }

    /// A space at a line edge survives when a marker sits between it and the edge: inside a code span
    /// (the writer closes and opens it at each break), or inside a link or `<u>` that starts and ends on this line.
    private static func isInsideMarkers(_ offset: Int, line: Range<Int>, spans: [RichSpan]) -> Bool {
        spans.contains { span in
            guard span.range.contains(offset) else { return false }
            switch span.style {
            case .code: return true
            case .link, .underline: return span.range.lowerBound >= line.lowerBound && span.range.upperBound <= line.upperBound
            case .bold, .italic, .strikethrough: return false
            }
        }
    }

    /// Emphasis cannot start or end with whitespace, so those spans shrink to their visible part.
    /// A span over only whitespace is dropped.
    private static func trimmedSpans(_ text: RichText) -> RichText {
        guard text.spans.contains(where: { $0.style == .bold || $0.style == .italic || $0.style == .strikethrough }) else { return text }
        let units = Array(text.text.utf16)
        let spans = text.spans.compactMap { span -> RichSpan? in
            switch span.style {
            case .bold, .italic, .strikethrough:
                var lower = span.range.lowerBound
                var upper = span.range.upperBound
                while lower < upper, isUnicodeWhitespace(units[lower]) { lower += 1 }
                while upper > lower, isUnicodeWhitespace(units[upper - 1]) { upper -= 1 }
                return lower < upper ? RichSpan(range: lower..<upper, style: span.style) : nil
            default:
                return span
            }
        }
        return text.withSpans(spans)
    }

    /// "\n" is a soft break, U+2028 a hard break.
    static func isBreak(_ unit: UInt16) -> Bool {
        unit == 10 || unit == 0x2028
    }

    private static func isSpaceOrTab(_ unit: UInt16) -> Bool {
        unit == 32 || unit == 9
    }

    /// CommonMark's Unicode whitespace: the Zs category, tab, line feed, form feed, carriage return. Also the hard break.
    private static func isUnicodeWhitespace(_ unit: UInt16) -> Bool {
        switch unit {
        case 9, 10, 12, 13, 32, 0x2028: true
        default: Unicode.Scalar(unit).map { $0.properties.generalCategory == .spaceSeparator } ?? false
        }
    }
}
