import MEGAMarkdown
import UIKit

/// The text view of one rich row: TextKit 1 with the inline code chip.
/// It reports the keys a row cannot handle alone: Backspace at the start, Tab, and arrows that leave the row.
final class RichTextView: UITextView {
    /// An edge of the text that a key leaves through.
    enum Edge: Equatable {
        case up, down, start, end
    }

    /// True while the model writes into the view. Delegate calls in that time are the model's own and are not reported.
    private(set) var isApplyingModel = false
    var modelUndoManager: ModelUndoManager?
    var onBackspaceAtStart: (() -> Void)?
    /// Tab and ⇧Tab. They type nothing when the row can indent or outdent.
    var canIndent: (() -> Bool)?
    var canOutdent: (() -> Bool)?
    var onIndent: (() -> Void)?
    var onOutdent: (() -> Void)?
    var indentTitle = ""
    var outdentTitle = ""
    /// An arrow key at the edge of the text: the caret goes to the row before or after.
    var onLeave: ((Edge) -> Void)?
    /// ⇧ with an arrow at the edge of the text: the selection grows past this row.
    var onShiftArrowAtEdge: ((Edge) -> Void)?
    /// False: the view adds no ⇧ arrow commands, so ⇧ with an arrow selects inside the row as usual.
    var canExtendPastEdge: (() -> Bool)?
    /// A text size or Bold Text change. The row styles its text again.
    var onTextSizeChange: (() -> Void)?
    /// The model's typing styles changed without a new row input, for example a style button at the caret.
    var onTypingStylesChange: (() -> Void)?
    /// Copy and cut return the model's content of the selection. nil: the system copies.
    var onCopy: (() -> RichClipboardContent?)?
    var onCut: (() -> RichClipboardContent?)?
    /// Paste gives the content to the model, which parses Markdown. Never typed through `shouldChangeTextIn`.
    var onPaste: ((RichPasteContent) -> Void)?
    /// Select All selects the whole document, not only this row.
    var onSelectAll: (() -> Void)?
    /// Tests use a named pasteboard: reading the general one without a user action waits for permission.
    var pasteboard = UIPasteboard.general
    /// Grows when the text or its attributes change, so the size cache knows when to measure again.
    var contentVersion = 0
    /// A text view made with its own container does not keep the text storage, so this keeps it alive.
    private var ownTextStorage: NSTextStorage?
    private var lastFit: (width: CGFloat, contentVersion: Int, size: CGSize)?
    /// The font of the row's plain text. See `InlineCodeLayoutManager.baseFont`.
    var baseFont: UIFont? {
        get { inlineCodeLayoutManager?.baseFont }
        set { inlineCodeLayoutManager?.baseFont = newValue }
    }

    /// A TextKit 1 stack with `InlineCodeLayoutManager`, so inline code gets its chip.
    static func make() -> RichTextView {
        let storage = NSTextStorage()
        let layoutManager = InlineCodeLayoutManager()
        // SwiftUI `Text` adds no font leading between lines, so rows are as tall as in the preview.
        layoutManager.usesFontLeading = false
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)
        let textView = RichTextView(frame: .zero, textContainer: container)
        layoutManager.delegate = textView
        textView.ownTextStorage = storage
        textView.isScrollEnabled = false
        // Only the row list scrolls to the top on a status bar tap.
        textView.scrollsToTop = false
        textView.backgroundColor = .clear
        // At the start or end of a line the inline code chip reaches past the text. The row pads the view back.
        let side = InlineCodeLayoutManager.chipPadding
        textView.textContainerInset = UIEdgeInsets(top: 0, left: side, bottom: 0, right: side)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self]) { (view: RichTextView, _) in
            view.onTextSizeChange?()
        }
        return textView
    }

    var inlineCodeLayoutManager: InlineCodeLayoutManager? {
        layoutManager as? InlineCodeLayoutManager
    }

    /// System undo goes to the model's stack. While text is marked, the input method owns it, so there is no undo.
    override var undoManager: UndoManager? {
        modelUndoManager?.forTextView(hasMarkedText: markedTextRange != nil)
    }

    // MARK: - Model writes

    /// Runs a write of the model into the view, so its delegate calls are not reported back.
    func applyingModel(_ change: () -> Void) {
        let wasApplying = isApplyingModel
        isApplyingModel = true
        change()
        isApplyingModel = wasApplying
    }

    /// Sets the selection the model holds. Not reported back as a user move.
    func setSelectionFromModel(_ range: NSRange) {
        let length = (text as NSString).length
        let location = min(range.location, length)
        let clamped = NSRange(location: location, length: min(range.length, length - location))
        guard clamped != selectedRange else { return }
        applyingModel { selectedRange = clamped }
    }

    /// Takes the keyboard for a caret the model placed. UIKit moves the caret while it becomes first responder,
    /// so the model's selection is set again after it.
    func focusFromModel(selection: NSRange) {
        applyingModel {
            if !isFirstResponder { becomeFirstResponder() }
            selectedRange = NSRange(location: 0, length: 0)
        }
        setSelectionFromModel(selection)
        // A caret move makes UIKit copy the attributes of the character before it. After a link that is the link look.
        onTypingStylesChange?()
    }

    // MARK: - Size

    /// UIKit lays the whole text out again on each `sizeThatFits`, and a hosted row asks more than once per pass.
    func fittingSize(width: CGFloat) -> CGSize {
        if let lastFit, lastFit.width == width, lastFit.contentVersion == contentVersion {
            return lastFit.size
        }
        var size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        if let manager = inlineCodeLayoutManager {
            size.height = manager.textHeight(usedHeight: size.height)
        }
        lastFit = (width, contentVersion, size)
        return size
    }

    /// A text view that does not scroll sizes its container to its bounds. The row can be a fraction of a point
    /// shorter than its lines, and TextKit 1 then leaves the last line out. An unlimited height keeps every line.
    override func layoutSubviews() {
        super.layoutSubviews()
        if textContainer.size.height != .greatestFiniteMagnitude {
            textContainer.size.height = .greatestFiniteMagnitude
        }
    }

    // MARK: - Clipboard

    override func copy(_ sender: Any?) {
        guard let content = onCopy?() else {
            super.copy(sender)
            return
        }
        RichPasteboard.write(content, to: pasteboard)
    }

    override func cut(_ sender: Any?) {
        guard let content = onCut?() else {
            super.cut(sender)
            return
        }
        RichPasteboard.write(content, to: pasteboard)
    }

    override func paste(_ sender: Any?) {
        guard let onPaste else {
            super.paste(sender)
            return
        }
        guard let content = RichPasteboard.read(from: pasteboard) else { return }
        onPaste(content)
    }

    override func selectAll(_ sender: Any?) {
        guard let onSelectAll else {
            super.selectAll(sender)
            return
        }
        onSelectAll()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)), onPaste != nil {
            return isEditable && RichPasteboard.canPaste(from: pasteboard)
        }
        return super.canPerformAction(action, withSender: sender)
    }

    // MARK: - Keys

    override func deleteBackward() {
        if selectedRange == NSRange(location: 0, length: 0), markedTextRange == nil, let onBackspaceAtStart {
            onBackspaceAtStart()
            return
        }
        super.deleteBackward()
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []
        if canIndent?() == true {
            commands.append(Self.command(indentTitle, "\t", [], #selector(indentPressed)))
        }
        if canOutdent?() == true {
            commands.append(Self.command(outdentTitle, "\t", .shift, #selector(outdentPressed)))
        }
        if markedTextRange == nil {
            commands += edgeCommands()
        }
        return commands + (super.keyCommands ?? [])
    }

    /// Arrow commands only at an edge, so inside the text the arrows move the caret as usual.
    private func edgeCommands() -> [UIKeyCommand] {
        guard let range = selectedTextRange else { return [] }
        var commands: [UIKeyCommand] = []
        let length = (text as NSString).length
        let isCaret = selectedRange.length == 0
        if isCaret, isOnFirstLine(range.start) {
            commands.append(Self.command("", UIKeyCommand.inputUpArrow, [], #selector(upPressed)))
        }
        if isCaret, isOnLastLine(range.end) {
            commands.append(Self.command("", UIKeyCommand.inputDownArrow, [], #selector(downPressed)))
        }
        if isCaret, selectedRange.location == 0 {
            commands.append(Self.command("", isRightToLeft ? UIKeyCommand.inputRightArrow : UIKeyCommand.inputLeftArrow, [], #selector(startPressed)))
        }
        if isCaret, selectedRange.location == length {
            commands.append(Self.command("", isRightToLeft ? UIKeyCommand.inputLeftArrow : UIKeyCommand.inputRightArrow, [], #selector(endPressed)))
        }
        guard canExtendPastEdge?() == true else { return commands }
        if isOnFirstLine(range.start) {
            commands.append(Self.command("", UIKeyCommand.inputUpArrow, .shift, #selector(shiftUpPressed)))
        }
        if isOnLastLine(range.end) {
            commands.append(Self.command("", UIKeyCommand.inputDownArrow, .shift, #selector(shiftDownPressed)))
        }
        return commands
    }

    private var isRightToLeft: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    private func isOnFirstLine(_ position: UITextPosition) -> Bool {
        caretRect(for: position).minY <= caretRect(for: beginningOfDocument).minY
    }

    private func isOnLastLine(_ position: UITextPosition) -> Bool {
        caretRect(for: position).minY >= caretRect(for: endOfDocument).minY
    }

    private static func command(_ title: String, _ input: String, _ flags: UIKeyModifierFlags, _ action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(title: title, action: action, input: input, modifierFlags: flags)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }

    @objc private func indentPressed() { onIndent?() }
    @objc private func outdentPressed() { onOutdent?() }
    @objc private func upPressed() { onLeave?(.up) }
    @objc private func downPressed() { onLeave?(.down) }
    @objc private func startPressed() { onLeave?(.start) }
    @objc private func endPressed() { onLeave?(.end) }
    @objc private func shiftUpPressed() { onShiftArrowAtEdge?(.up) }
    @objc private func shiftDownPressed() { onShiftArrowAtEdge?(.down) }
}

// MARK: - NSLayoutManagerDelegate

// The text view lays out its text on the main thread.
extension RichTextView: @preconcurrency NSLayoutManagerDelegate {
    /// See `InlineCodeLayoutManager.setLineFragmentRect(_:usedRect:baselineOffset:)`.
    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange
    ) -> Bool {
        inlineCodeLayoutManager?.setLineFragmentRect(lineFragmentRect, usedRect: lineFragmentUsedRect, baselineOffset: baselineOffset) ?? false
    }
}
