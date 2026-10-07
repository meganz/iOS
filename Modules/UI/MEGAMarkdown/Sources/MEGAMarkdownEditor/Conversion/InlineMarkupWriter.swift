import Foundation

/// One writing of a cleaned `RichText`, with Markdown markers or with HTML tags.
/// `InlineWriter` picks the writing that parses back.
struct InlineMarkupWriter {
    private let units: [UInt16]
    private let spans: [RichSpan]
    private let context: InlineWriter.Context
    private let usesHTML: Bool

    private struct Open {
        let style: RichSpanStyle
        /// The span this marker opened. A touching span of the same style is another marker pair.
        let range: Range<Int>
        let closer: String
    }

    init(text: RichText, context: InlineWriter.Context, usesHTML: Bool) {
        units = Array(text.text.utf16)
        spans = Self.splitAtLinkEdges(text.spans)
        self.context = context
        self.usesHTML = usesHTML
    }

    /// Emphasis cannot open outside link text and close inside it. A style that crosses a link edge is cut there.
    /// The cut pieces touch, so a re-import joins them again.
    private static func splitAtLinkEdges(_ spans: [RichSpan]) -> [RichSpan] {
        let links = spans.filter { $0.style.isLink }.map(\.range)
        guard !links.isEmpty else { return spans }
        var result: [RichSpan] = []
        for span in spans {
            guard !span.style.isLink else {
                result.append(span)
                continue
            }
            var cuts: [Int] = []
            for link in links where span.range.overlaps(link) {
                let contains = span.range.lowerBound <= link.lowerBound && link.upperBound <= span.range.upperBound
                let inside = link.lowerBound <= span.range.lowerBound && span.range.upperBound <= link.upperBound
                guard !contains && !inside else { continue }
                if span.range.contains(link.lowerBound) && link.lowerBound > span.range.lowerBound { cuts.append(link.lowerBound) }
                if span.range.contains(link.upperBound) && link.upperBound > span.range.lowerBound { cuts.append(link.upperBound) }
            }
            var lower = span.range.lowerBound
            for cut in cuts.sorted() where cut > lower && cut < span.range.upperBound {
                result.append(RichSpan(range: lower..<cut, style: span.style))
                lower = cut
            }
            result.append(RichSpan(range: lower..<span.range.upperBound, style: span.style))
        }
        // Sorted by start, like `RichText` keeps them. The pieces must not merge back, so this is not normalized.
        return result.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    func write() -> String {
        var boundaries = Set([0, units.count])
        for span in spans {
            boundaries.insert(span.range.lowerBound)
            boundaries.insert(span.range.upperBound)
        }
        for (index, unit) in units.enumerated() where InlineTextCleaner.isBreak(unit) {
            boundaries.insert(index)
            boundaries.insert(index + 1)
        }
        let segments = segments(at: boundaries.sorted())
        // Code is innermost, so it closes at any change of the active styles. Its piece runs to the next change.
        var pieceEnds = segments.map(\.range.upperBound)
        for index in segments.indices.dropLast().reversed() where segments[index].active == segments[index + 1].active {
            pieceEnds[index] = pieceEnds[index + 1]
        }
        let prefix = context.continuationPrefix

        var output = ""
        var stack: [Open] = []
        var atLineStart = true
        // An autolink `<url>` writes its text in the marker, so the text itself is skipped up to here.
        var skipUntil = 0
        for (index, segment) in segments.enumerated() {
            let (start, end) = (segment.range.lowerBound, segment.range.upperBound)
            let isBreak = segment.isBreak
            let active = segment.active
            transition(&stack, to: active, codePiece: start..<pieceEnds[index], output: &output, skipUntil: &skipUntil)
            if start < skipUntil { continue }

            let piece = String(decoding: units[start..<end], as: UTF16.self)
            if isBreak {
                output += (units[start] == 10 ? "\n" : "\\\n") + prefix
                atLineStart = true
            } else if active[.code] != nil && !usesHTML {
                output += piece
                atLineStart = false
            } else {
                output += MarkdownTextEscaper.escape(piece, atLineStart: &atLineStart, isATXHeading: context == .atxHeading)
            }
        }
        transition(&stack, to: [:], codePiece: 0..<0, output: &output, skipUntil: &skipUntil)
        return output
    }

    private struct Segment {
        let range: Range<Int>
        let isBreak: Bool
        /// The spans on this segment, by style.
        let active: [RichSpanStyle: Range<Int>]
    }

    /// The text between neighbour boundaries, with the spans on it. One walk over the spans (sorted by start):
    /// checking every span per segment would be quadratic.
    private func segments(at points: [Int]) -> [Segment] {
        var result: [Segment] = []
        var nextSpan = 0
        var covering: [RichSpan] = []
        for (start, end) in zip(points, points.dropFirst()) where start < end {
            while nextSpan < spans.count, spans[nextSpan].range.lowerBound <= start {
                covering.append(spans[nextSpan])
                nextSpan += 1
            }
            covering.removeAll { $0.range.upperBound <= start }
            let isBreak = end - start == 1 && InlineTextCleaner.isBreak(units[start])
            var active: [RichSpanStyle: Range<Int>] = [:]
            for span in covering where end <= span.range.upperBound {
                // A code span cannot hold a line end: it closes before the break and opens again after it.
                if isBreak && span.style == .code { continue }
                active[span.style] = span.range
            }
            result.append(Segment(range: start..<end, isBreak: isBreak, active: active))
        }
        return result
    }

    /// Closes what ends here, then opens what starts here. Code always stays innermost.
    /// `codePiece`: the text a code marker opened here holds, up to where it closes.
    private func transition(
        _ stack: inout [Open],
        to active: [RichSpanStyle: Range<Int>],
        codePiece: Range<Int>,
        output: inout String,
        skipUntil: inout Int
    ) {
        var popFrom = stack.firstIndex { active[$0.style] != $0.range } ?? stack.count
        let openStyles = Set(stack[..<popFrom].map(\.style))
        let toOpen = active.keys.filter { !openStyles.contains($0) }
        if !toOpen.isEmpty, let codeIndex = stack.firstIndex(where: { $0.style == .code }) {
            popFrom = min(popFrom, codeIndex)
        }
        while stack.count > popFrom {
            output += stack.removeLast().closer
        }
        let remaining = Set(stack.map(\.style))
        // Markers that stay open keep their place. Everything else opens again, outer (longer) first.
        let opening = active.filter { !remaining.contains($0.key) }.sorted { lhs, rhs in
            if (lhs.key == .code) != (rhs.key == .code) { return rhs.key == .code }
            if lhs.value.upperBound != rhs.value.upperBound { return lhs.value.upperBound > rhs.value.upperBound }
            return lhs.key.rank < rhs.key.rank
        }
        for (style, range) in opening {
            if case .link(let link) = style, let autolink = autolink(link, range: range) {
                output += autolink
                skipUntil = range.upperBound
                stack.append(Open(style: style, range: range, closer: ""))
                continue
            }
            let (opener, closer) = markers(for: style, range: range, codePiece: codePiece, after: output.last)
            output += opener
            stack.append(Open(style: style, range: range, closer: closer))
        }
    }

    private func markers(for style: RichSpanStyle, range: Range<Int>, codePiece: Range<Int>, after previous: Character?) -> (String, String) {
        if case .link(let link) = style {
            return ("[", "](" + MarkdownTextEscaper.destination(link.destination) + MarkdownTextEscaper.title(link.title) + ")")
        }
        if usesHTML {
            switch style {
            case .bold: return ("<strong>", "</strong>")
            case .italic: return ("<em>", "</em>")
            case .strikethrough: return ("<del>", "</del>")
            case .underline: return ("<u>", "</u>")
            case .code: return ("<code>", "</code>")
            case .link: return ("", "")
            }
        }
        // `**abc*def****ghi*` is misread: a `*` opener right after a `*` closer joins it into one run.
        // `_` avoids that, but it cannot close inside a word, so it is used only at a word end.
        let next = range.upperBound < units.count ? Unicode.Scalar(units[range.upperBound]).map(Character.init) : nil
        let nextIsWord = next.map { $0.isLetter || $0.isNumber } ?? false
        let useUnderscore = previous == "*" && !nextIsWord
        switch style {
        case .bold: return useUnderscore ? ("__", "__") : ("**", "**")
        case .italic: return useUnderscore ? ("_", "_") : ("*", "*")
        case .strikethrough: return ("~~", "~~")
        case .underline: return ("<u>", "</u>")
        case .link: return ("", "")
        case .code:
            // The backticks fit the piece this marker holds. A code span cut by other styles has several pieces.
            let content = String(decoding: units[codePiece], as: UTF16.self)
            let scalars = content.unicodeScalars
            var longest = 0
            var run = 0
            for scalar in scalars {
                run = scalar == "`" ? run + 1 : 0
                longest = max(longest, run)
            }
            let ticks = String(repeating: "`", count: longest + 1)
            // cmark strips one space from both ends of a code span when both are spaces.
            let pad = scalars.first == "`" || scalars.last == "`"
                || (scalars.first == " " && scalars.last == " " && !scalars.allSatisfy { $0 == " " })
            return pad ? (ticks + " ", " " + ticks) : (ticks, ticks)
        }
    }

    /// `<https://mega.nz>` when the link has no title and no inner style, and its text is the URL.
    private func autolink(_ link: RichLink, range: Range<Int>) -> String? {
        guard link.title.isEmpty, !spans.contains(where: { !$0.style.isLink && $0.range.overlaps(range) }) else { return nil }
        return MarkdownTextEscaper.autolink(text: String(decoding: units[range], as: UTF16.self), destination: link.destination)
    }
}
