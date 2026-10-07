import Foundation

/// Moves spans through one text edit.
enum RichSpanAdjuster {
    /// `editRange` is the replaced UTF-16 range in the old text.
    /// With `typingStyles`, the inserted text gets exactly those styles, so a style turned off at the caret
    /// stays off inside a styled word. Without, inserted text strictly inside a span joins it.
    static func adjust(
        _ spans: [RichSpan],
        editRange: Range<Int>,
        replacementLength: Int,
        typingStyles: Set<RichSpanStyle>?
    ) -> [RichSpan] {
        let start = editRange.lowerBound
        let end = editRange.upperBound
        let delta = replacementLength - editRange.count
        let inserted = start..<(start + replacementLength)
        var result: [RichSpan] = []
        result.reserveCapacity(spans.count + (typingStyles?.count ?? 0))

        for span in spans {
            let lower = span.range.lowerBound
            let upper = span.range.upperBound
            if upper <= start {
                result.append(span)
                continue
            }
            if lower >= end {
                // Wholly after the edit. An insert at a span start does not join the span.
                result.append(RichSpan(range: (lower + delta)..<(upper + delta), style: span.style))
                continue
            }
            // The span touches the edit. Keep its parts outside the replaced range.
            if lower < start {
                result.append(RichSpan(range: lower..<start, style: span.style))
            }
            if upper > end {
                result.append(RichSpan(range: (end + delta)..<(upper + delta), style: span.style))
            }
            // The inserted text joins the span when the edit sits strictly inside it.
            if typingStyles == nil && replacementLength > 0 && lower < start && end < upper {
                result.append(RichSpan(range: inserted, style: span.style))
            }
        }
        if replacementLength > 0, let typingStyles {
            for style in typingStyles {
                result.append(RichSpan(range: inserted, style: style))
            }
        }
        return result
    }
}

extension RichText {
    /// Adds the style to the range, or removes it when every character in the range has it already.
    /// A link replaces other links in the range. Toggling the same link again removes it.
    func togglingStyle(_ style: RichSpanStyle, in range: Range<Int>) -> RichText {
        let lower = max(0, min(range.lowerBound, length))
        let upper = max(lower, min(range.upperBound, length))
        guard lower < upper else { return self }
        let target = lower..<upper
        return isCovered(by: style, target) ? removingStyle(style, in: target) : addingStyle(style, in: target)
    }

    /// True when every character in `range` has `style`. False for an empty range.
    func isCovered(by style: RichSpanStyle, _ range: Range<Int>) -> Bool {
        guard !range.isEmpty else { return false }
        var position = range.lowerBound
        for span in spans where span.style == style && span.range.lowerBound <= position {
            if span.range.upperBound > position { position = span.range.upperBound }
            if position >= range.upperBound { return true }
        }
        return position >= range.upperBound
    }

    /// A link removes the other links in the range first: a character has at most one link.
    func addingStyle(_ style: RichSpanStyle, in range: Range<Int>) -> RichText {
        guard !range.isEmpty else { return self }
        var result = style.isLink ? Self.removing(spans, in: range) { $0.isLink } : spans
        result.append(RichSpan(range: range, style: style))
        return withSpans(result)
    }

    func removingStyle(_ style: RichSpanStyle, in range: Range<Int>) -> RichText {
        withSpans(Self.removing(spans, in: range) { $0 == style })
    }

    /// Removes links only inside `range`. Link text outside the range keeps its link.
    func removingLinks(in range: Range<Int>) -> RichText {
        withSpans(Self.removing(spans, in: range) { $0.isLink })
    }

    /// Styles on every character of `range`. For an empty range: the styles a caret there types with.
    /// Those are the styles of the character before it (after it at offset 0).
    /// A link does not continue past its end, so typing after a link is plain.
    func styles(in range: Range<Int>) -> Set<RichSpanStyle> {
        let lower = max(0, min(range.lowerBound, length))
        let upper = max(lower, min(range.upperBound, length))
        if lower < upper {
            return Set(spans.lazy.map(\.style)).filter { isCovered(by: $0, lower..<upper) }
        }
        guard length > 0 else { return [] }
        let probe = lower == 0 ? 0 : lower - 1
        var result = Set<RichSpanStyle>()
        for span in spans where span.range.contains(probe) {
            if span.style.isLink && lower == span.range.upperBound { continue }
            result.insert(span.style)
        }
        return result
    }

    /// The link span that holds the caret (also at its edges) or overlaps the range.
    func link(at range: Range<Int>) -> RichSpan? {
        spans.first { span in
            guard span.style.isLink else { return false }
            if range.isEmpty {
                return span.range.lowerBound <= range.lowerBound && range.lowerBound <= span.range.upperBound
            }
            return span.range.overlaps(range)
        }
    }

    private static func removing(_ spans: [RichSpan], in range: Range<Int>, where matches: (RichSpanStyle) -> Bool) -> [RichSpan] {
        var result: [RichSpan] = []
        for span in spans {
            guard matches(span.style), span.range.overlaps(range) else {
                result.append(span)
                continue
            }
            if span.range.lowerBound < range.lowerBound {
                result.append(RichSpan(range: span.range.lowerBound..<range.lowerBound, style: span.style))
            }
            if span.range.upperBound > range.upperBound {
                result.append(RichSpan(range: range.upperBound..<span.range.upperBound, style: span.style))
            }
        }
        return result
    }
}
