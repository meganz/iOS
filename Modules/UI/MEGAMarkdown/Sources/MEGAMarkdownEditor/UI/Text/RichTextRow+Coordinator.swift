import MEGAMarkdown
import UIKit

extension RichTextRow {
    /// Writes the model into the text view and reports the user's edits and caret moves to the model.
    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        weak var textView: RichTextView?
        weak var host: (any RichTextRowHost)?
        var input: RichTextRow?
        var lastHeight: CGFloat = 0
        /// The model version of the text the view holds: the input it took, or the edit it made.
        private(set) var heldVersion = -1
        /// The row of the text the view holds.
        private var heldID: RichRowID?
        /// The inputs of the last write that are not in the row input.
        private var heldLook: Look?
        /// An input came while text was marked. It is written when the marked text ends.
        private var isDirty = false
        /// The edit UIKit is about to make, from `shouldChangeTextIn`.
        private var pendingEdit: (range: NSRange, text: String)?

        private struct Look: Equatable {
            let contentSize: UIContentSizeCategory
            let legibility: UILegibilityWeight
            let isRightToLeft: Bool
            let theme: MarkdownTheme
        }

        // MARK: - Model to view

        /// Writes the input into the view when it is newer than what the view holds, or when the look changed.
        /// Never while text is marked: that would cancel the input method's text.
        func apply(force: Bool) {
            guard let textView, let input else { return }
            guard textView.markedTextRange == nil else {
                isDirty = true
                return
            }
            let traits = textView.traitCollection
            let look = Look(
                contentSize: traits.preferredContentSizeCategory,
                legibility: traits.legibilityWeight,
                isRightToLeft: traits.layoutDirection == .rightToLeft,
                theme: input.theme
            )
            // Rows of one model version share the version, so only the identity tells a new row apart.
            let isOtherRow = input.id != heldID
            guard force || isDirty || isOtherRow || input.version > heldVersion || look != heldLook else {
                refreshTypingAttributes()
                return
            }
            isDirty = false
            heldVersion = isOtherRow ? input.version : max(heldVersion, input.version)
            heldID = input.id
            heldLook = look
            let styler = styler(for: textView)
            textView.inlineCodeLayoutManager?.fillColor = styler.resolved.inlineCodeBackground
            textView.inlineCodeLayoutManager?.borderColor = styler.resolved.inlineCodeBorder
            textView.inlineCodeLayoutManager?.chipHeight = styler.resolved.inlineCodeChipHeight
            textView.inlineCodeLayoutManager?.lineGap = styler.resolved.inlineCodeLineGap
            let block = currentBlock(of: textView, input: input)
            textView.baseFont = RichTextStyler.kind(of: block).map(styler.baseFont)
            let expected = styler.attributedString(block)
            if !textView.attributedText.isEqual(to: expected) {
                write(expected, to: textView)
            }
            if expected.length == 0, let kind = RichTextStyler.kind(of: block) {
                styleEmptyText(textView, styler: styler, kind: kind)
            }
            refreshTypingAttributes()
        }

        /// After a key, the view is newer than `input`. The model row has the typed text, so a forced restyle uses it.
        private func currentBlock(of textView: RichTextView, input: RichTextRow) -> RichBlock {
            guard heldVersion > input.version, let host, let row = host.row(of: textView), row < host.model.rowCount else {
                return input.block
            }
            return host.model.row(at: row).block
        }

        /// An empty text view draws its caret with its own font, not with the typing attributes.
        /// So an empty row takes the base style of its kind, and the caret is as tall as the row's text.
        private func styleEmptyText(_ textView: RichTextView, styler: RichTextStyler, kind: RichTextStyler.Kind) {
            let attributes = styler.attributes(for: [], kind: kind)
            textView.applyingModel {
                textView.font = attributes[.font] as? UIFont
                textView.typingAttributes = attributes
            }
        }

        /// Equal bytes: only the attributes change, in place, so the caret and the input method state stay.
        private func write(_ expected: NSAttributedString, to textView: RichTextView) {
            textView.applyingModel {
                if textView.text.hasSameBytes(as: expected.string) {
                    let storage = textView.textStorage
                    storage.beginEditing()
                    expected.enumerateAttributes(in: NSRange(location: 0, length: expected.length)) { attributes, range, _ in
                        storage.setAttributes(attributes, range: range)
                    }
                    storage.endEditing()
                } else {
                    let selection = modelSelection(in: textView) ?? textView.selectedRange
                    textView.attributedText = expected
                    let length = expected.length
                    let location = min(selection.location, length)
                    textView.selectedRange = NSRange(location: location, length: min(selection.length, length - location))
                }
            }
            textView.contentVersion += 1
            textView.invalidateIntrinsicContentSize()
        }

        /// The model's selection when it is in this row. New text can arrive after the focus path set the caret
        /// (a paste in the focused row), so the model's caret wins over the view's old one.
        private func modelSelection(in textView: RichTextView) -> NSRange? {
            guard textView.isFirstResponder, let host, let row = host.row(of: textView) else { return nil }
            let selection = host.model.selection
            guard selection.isInOneBlock, selection.start.blockIndex == row else { return nil }
            return NSRange(location: selection.start.offset, length: selection.end.offset - selection.start.offset)
        }

        /// Typed text gets the model's typing styles, so a style turned on at the caret shows on the next key.
        func refreshTypingAttributes() {
            guard let textView, textView.isFirstResponder, let input, let model = host?.model,
                  let kind = RichTextStyler.kind(of: input.block) else { return }
            let attributes = styler(for: textView).attributes(for: kind == .code ? [] : model.typingStyles, kind: kind)
            textView.typingAttributes = attributes
        }

        private func styler(for textView: RichTextView) -> RichTextStyler {
            let theme = input?.theme ?? .default
            return RichTextStyler(
                resolved: theme.resolved(for: textView.traitCollection),
                isRightToLeft: textView.traitCollection.layoutDirection == .rightToLeft
            )
        }

        // MARK: - Keys

        func wireKeys(_ textView: RichTextView) {
            textView.onBackspaceAtStart = { [weak self, weak textView] in
                guard let self, let textView, let model = host?.model, let row = host?.row(of: textView) else { return }
                model.select(.caret(RichPosition(blockIndex: row, offset: 0)))
                model.deleteBackward()
            }
            textView.canIndent = { [weak self] in self?.host?.model.toolbar.canIndent ?? false }
            textView.canOutdent = { [weak self] in self?.host?.model.toolbar.canOutdent ?? false }
            textView.onIndent = { [weak self] in self?.host?.model.apply(.indent) }
            textView.onOutdent = { [weak self] in self?.host?.model.apply(.outdent) }
            textView.onLeave = { [weak self, weak textView] edge in
                guard let textView else { return }
                self?.host?.textView(textView, didLeaveThrough: edge)
            }
            textView.onShiftArrowAtEdge = { [weak self, weak textView] edge in
                guard let textView else { return }
                self?.host?.textView(textView, didShiftArrowAtEdge: edge)
            }
            textView.canExtendPastEdge = { [weak self] in self?.host?.canExtendSelectionPastEdge ?? false }
            textView.onTextSizeChange = { [weak self] in
                self?.apply(force: true)
            }
            textView.onTypingStylesChange = { [weak self] in
                self?.refreshTypingAttributes()
            }
            textView.onCopy = { [weak self, weak textView] in
                guard let self, let textView, let model = syncSelection(of: textView) else { return nil }
                return model.copy()
            }
            textView.onCut = { [weak self, weak textView] in
                guard let self, let textView, let model = syncSelection(of: textView) else { return nil }
                return model.cut()
            }
            textView.onSelectAll = { [weak self, weak textView] in
                guard let textView else { return }
                self?.host?.textViewDidRequestSelectAll(textView)
            }
            textView.onPaste = { [weak self, weak textView] content in
                guard let self, let textView else { return }
                if textView.markedTextRange != nil { textView.unmarkText() }
                syncSelection(of: textView)?.paste(content)
            }
        }

        /// The model's selection set to the view's, before a clipboard action reads it. Returns the model.
        @discardableResult
        private func syncSelection(of textView: RichTextView) -> RichEditorModel? {
            guard let host, let row = host.row(of: textView) else { return nil }
            let selected = textView.selectedRange
            let selection = RichSelection.range(selected.location..<NSMaxRange(selected), inBlock: row)
            if selection != host.model.selection { host.model.select(selection) }
            return host.model
        }

        // MARK: - Edit menu

        /// The system menu, plus Link when text is selected in a text row.
        @available(iOS 26.0, *)
        func textView(_ textView: UITextView, editMenuForTextInRanges ranges: [NSValue], suggestedActions: [UIMenuElement]) -> UIMenu? {
            editMenu(for: textView, suggestedActions: suggestedActions)
        }

        /// iOS 17 to 25 ask with one range.
        func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            editMenu(for: textView, suggestedActions: suggestedActions)
        }

        private func editMenu(for textView: UITextView, suggestedActions: [UIMenuElement]) -> UIMenu? {
            guard let textView = textView as? RichTextView, textView.selectedRange.length > 0,
                  let input, input.block.richText != nil else { return nil }
            let link = UIAction(title: input.strings.link, image: MarkdownEditorIcon.link.uiImage) { [weak self, weak textView] _ in
                guard let self, let textView else { return }
                syncSelection(of: textView)?.beginLinkEditing()
            }
            return UIMenu(children: suggestedActions + [link])
        }

        // MARK: - View to model

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let textView = textView as? RichTextView, !textView.isApplyingModel else { return true }
            guard let host, let row = host.row(of: textView) else { return false }
            let isLineBreak = text.utf8.contains { $0 == 10 || $0 == 13 }
            guard isLineBreak else {
                pendingEdit = (range, text)
                return true
            }
            // Commit the input method's text first, so the model has it before the row splits.
            // A text replacement, dictation or a drop can insert away from the caret, so `range` is the target.
            var replaced = range.location..<NSMaxRange(range)
            if textView.markedTextRange != nil {
                // `range` covers the marked text, which unmarking keeps. The break goes after it, at the caret.
                textView.unmarkText()
                let selected = textView.selectedRange
                replaced = selected.location..<NSMaxRange(selected)
            }
            if case .codeBlock = input?.block, text == "\n" {
                // Enter in code adds a line, or leaves the block on an empty last line.
                host.model.select(.range(replaced, inBlock: row))
                host.model.insertParagraphBreak()
            } else {
                host.model.replaceText(inRow: row, range: replaced, with: text)
            }
            return false
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let textView = textView as? RichTextView, !textView.isApplyingModel else { return }
            let edit = pendingEdit
            pendingEdit = nil
            guard let host, let row = host.row(of: textView) else { return }
            let length = (textView.text as NSString).length
            // The announced range is exact when the view grew by what the model expects from it.
            var holdsModel: Bool
            if textView.markedTextRange == nil, let edit,
               length == host.model.row(at: row).block.length - edit.range.length + edit.text.utf16.count {
                host.model.replaceText(inRow: row, range: edit.range.location..<NSMaxRange(edit.range), with: edit.text)
                holdsModel = holdsModelText(textView, row: row)
                // A keyboard can apply another range of the same length than it announced. The view's bytes win.
                if !holdsModel {
                    host.model.didChangeText(inRow: row, to: textView.text, caret: NSMaxRange(textView.selectedRange))
                    holdsModel = holdsModelText(textView, row: row)
                }
            } else {
                // Dictation, some keyboards and marked text change the text without a matching range.
                // During composition the caret can sit inside the marked text, so it is not the edit end.
                let caret = textView.markedTextRange == nil ? NSMaxRange(textView.selectedRange) : nil
                host.model.didChangeText(inRow: row, to: textView.text, caret: caret)
                holdsModel = holdsModelText(textView, row: row)
            }
            // A line break split the row in the model, so the view does not hold the model's text then.
            if holdsModel {
                heldVersion = host.model.version
            }
            textView.contentVersion += 1
            // The view may drop the custom chip attribute from typed text. A restyle puts it back.
            if holdsModel, host.model.typingStyles.contains(.code) { isDirty = true }
            if isDirty, textView.markedTextRange == nil { apply(force: true) }
            let height = textView.fittingSize(width: textView.bounds.width).height
            if height != lastHeight {
                lastHeight = height
                textView.invalidateIntrinsicContentSize()
                host.textViewDidChangeHeight(textView)
            }
        }

        /// Byte equality of the view text and the model row. `String ==` would call different forms of "é" equal.
        private func holdsModelText(_ textView: RichTextView, row: Int) -> Bool {
            guard let host, let modelText = host.model.row(at: row).block.plainText else { return false }
            return textView.text.hasSameBytes(as: modelText)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let textView = textView as? RichTextView, textView.isFirstResponder else { return }
            reportSelection(of: textView)
        }

        /// Gives a user's caret move or selection to the model. Not the model's own writes, not typing, not marked text.
        private func reportSelection(of textView: RichTextView) {
            guard !textView.isApplyingModel, pendingEdit == nil, textView.markedTextRange == nil,
                  let host, let row = host.row(of: textView) else { return }
            // An edit without `shouldChangeTextIn` (dictation, code) reports the new caret before the new text.
            guard (textView.text as NSString).length == host.model.row(at: row).block.length else { return }
            let selected = textView.selectedRange
            let selection = RichSelection.range(selected.location..<NSMaxRange(selected), inBlock: row)
            // The caret move that typing makes is already in the model. A select() then would reset the typing styles.
            guard selection != host.model.selection else { return }
            host.model.select(selection)
            refreshTypingAttributes()
        }

        /// A tap into another row sets the selection before this view becomes first responder, so that change was
        /// not reported. The user's start selection goes to the model now. When the model moved the focus, it is
        /// applying the model, and its caret stays.
        func textViewDidBeginEditing(_ textView: UITextView) {
            guard let textView = textView as? RichTextView else { return }
            host?.textViewDidBeginEditing(textView)
            reportSelection(of: textView)
            refreshTypingAttributes()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard let textView = textView as? RichTextView else { return }
            host?.textViewDidEndEditing(textView)
        }
    }
}
