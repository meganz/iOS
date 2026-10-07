import Foundation

/// The block and range the link dialog edits. Captured when the dialog opens: the dialog's text field takes
/// focus, and the block's end of editing would clear the selection.
struct RichLinkTarget: Equatable, Sendable {
    let blockIndex: Int
    let range: Range<Int>
}

/// What the link dialog shows first.
struct RichLinkDraft: Equatable, Sendable {
    /// The destination of the link being edited, or empty for a new link.
    var url: String
    /// The selected text, so the user does not type it twice.
    var text: String
    /// True when the target has a link already. The dialog then offers Remove.
    var isEditing: Bool
}

extension RichEditor {
    /// The link target for the current selection: a range or a caret inside one text block.
    /// A caret inside a link edits the whole link. nil for a selection across blocks or outside text.
    func linkTarget() -> RichLinkTarget? {
        guard let range = selection.rangeInBlock, let text = rows[selection.start.blockIndex].block.richText else { return nil }
        if range.isEmpty, let link = text.link(at: range) {
            return RichLinkTarget(blockIndex: selection.start.blockIndex, range: link.range)
        }
        return RichLinkTarget(blockIndex: selection.start.blockIndex, range: range)
    }

    func linkDraft(for target: RichLinkTarget) -> RichLinkDraft {
        guard let text = richText(at: target) else { return RichLinkDraft(url: "", text: "", isEditing: false) }
        let label = text.slice(target.range).text
        guard let link = text.link(at: target.range), case .link(let value) = link.style else {
            return RichLinkDraft(url: "", text: label, isEditing: false)
        }
        return RichLinkDraft(url: value.destination, text: label, isEditing: true)
    }

    /// Adds or changes the link on the target. Returns false when nothing changed: the URL is not valid,
    /// or the block changed since the dialog opened. An empty label uses the URL as typed.
    @discardableResult
    mutating func saveLink(_ target: RichLinkTarget, urlText: String, label: String) -> Bool {
        let typedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var text = richText(at: target) else { return false }
        let oldLink = text.link(at: target.range).flatMap { span -> RichLink? in
            if case .link(let value) = span.style { value } else { nil }
        }
        // An unchanged URL stays as it is, even when it has spaces the dialog would not accept as new text.
        let isSameURL = oldLink.map { $0.destination.hasSameBytes(as: typedURL) } ?? false
        guard let destination = isSameURL ? oldLink?.destination : RichLinkURL.destination(from: typedURL) else { return false }
        let newLabel = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? typedURL : label
        var range = target.range
        if !text.slice(range).text.hasSameBytes(as: newLabel) {
            text = text.replacing(range, with: newLabel)
            range = range.lowerBound..<(range.lowerBound + newLabel.utf16.count)
        }
        guard !range.isEmpty else { return false }
        text = text.addingStyle(.link(RichLink(destination: destination, title: oldLink?.title ?? "")), in: range)
        write(text, at: target, caret: range.upperBound)
        return true
    }

    /// Removes the links inside the target. Link text outside it keeps its link.
    mutating func removeLink(_ target: RichLinkTarget) {
        guard let text = richText(at: target) else { return }
        write(text.removingLinks(in: target.range), at: target, caret: target.range.upperBound)
    }

    /// nil when the block or the range no longer exists.
    private func richText(at target: RichLinkTarget) -> RichText? {
        guard rows.indices.contains(target.blockIndex), let text = rows[target.blockIndex].block.richText,
              target.range.upperBound <= text.length else { return nil }
        return text
    }

    private mutating func write(_ text: RichText, at target: RichLinkTarget, caret: Int) {
        var blocks = rows.map(\.block)
        blocks[target.blockIndex] = blocks[target.blockIndex].withText(text)
        commit(blocks, caret: RichPosition(blockIndex: target.blockIndex, offset: caret))
    }
}

/// Turns what the user typed in the link dialog into a link destination.
enum RichLinkURL {
    /// The typed text, as written. CommonMark and the Android editor accept any destination without spaces,
    /// and a relative path such as "docs/guide.md" or "README.md" must stay a path.
    /// nil for empty text, text with spaces, and `javascript:` (a script link runs code in a web view).
    static func destination(from text: String) -> String? {
        guard !text.isEmpty, !text.contains(where: \.isWhitespace) else { return nil }
        if text.lowercased().hasPrefix("javascript:") { return nil }
        return text
    }

    /// The dialog's Save is on only when the typed URL makes a valid link.
    static func canSave(urlText: String) -> Bool {
        destination(from: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
}
