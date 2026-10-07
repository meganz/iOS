import MEGAMarkdown

/// Compares two parse results by meaning: what a reader of the rendered Markdown sees.
///
/// It ignores what the rich model does not keep: source lines, list markers (`-` or `*`, `.` or `)`),
/// tight or loose lists, and how style runs were split. Text compares by bytes.
/// The importer uses it to prove that the rich blocks write back the same document.
enum ParsedBlockEquivalence {
    static func isEquivalent(_ lhs: [ParsedBlock], _ rhs: [ParsedBlock]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { isEquivalent($0, $1) }
    }

    static func isEquivalent(_ lhs: ParsedBlock, _ rhs: ParsedBlock) -> Bool {
        switch (lhs.kind, rhs.kind) {
        case let (.heading(leftLevel, leftText), .heading(rightLevel, rightText)):
            return leftLevel == rightLevel && isEquivalent(leftText, rightText)
        case let (.paragraph(leftText), .paragraph(rightText)):
            return isEquivalent(leftText, rightText)
        case let (.list(left), .list(right)):
            return left.isOrdered == right.isOrdered && left.startIndex == right.startIndex
                && left.items.count == right.items.count
                && zip(left.items, right.items).allSatisfy { $0.checkbox == $1.checkbox && isEquivalent($0.blocks, $1.blocks) }
        case let (.codeBlock(leftLanguage, leftCode), .codeBlock(rightLanguage, rightCode)):
            return leftLanguage == rightLanguage && leftCode.hasSameBytes(as: rightCode)
        case let (.blockQuote(left), .blockQuote(right)):
            return isEquivalent(left, right)
        case let (.table(left), .table(right)):
            return left.columns == right.columns
                && left.header.count == right.header.count && zip(left.header, right.header).allSatisfy(isEquivalent)
                && left.rows.count == right.rows.count
                && zip(left.rows, right.rows).allSatisfy { $0.count == $1.count && zip($0, $1).allSatisfy(isEquivalent) }
        case (.thematicBreak, .thematicBreak):
            return true
        case let (.image(leftURL, leftAlt), .image(rightURL, rightAlt)):
            return leftURL == rightURL && leftAlt.hasSameBytes(as: rightAlt)
        default:
            return false
        }
    }

    static func isEquivalent(_ lhs: InlineText, _ rhs: InlineText) -> Bool {
        lhs.text.hasSameBytes(as: rhs.text) && runs(of: lhs) == runs(of: rhs)
    }

    private struct Run: Equatable {
        var end: Int
        var style: InlineStyle
        var link: InlineLink?
    }

    /// Runs with the link looked up, and neighbours with the same style and target joined.
    private static func runs(of text: InlineText) -> [Run] {
        var result: [Run] = []
        for run in text.runs {
            let link = run.link >= 0 && run.link < text.links.count ? text.links[run.link] : nil
            if let last = result.last, last.style == run.style, last.link == link {
                result[result.count - 1].end = run.end
            } else {
                result.append(Run(end: run.end, style: run.style, link: link))
            }
        }
        return result
    }
}
