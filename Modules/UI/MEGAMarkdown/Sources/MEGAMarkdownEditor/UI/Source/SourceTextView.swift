import MEGADesignToken
import SwiftUI
import UIKit

/// Plain text editor for the Markdown source. A key edits the text storage in place.
/// TextKit 1: a key in a 10 MB text stays fast. TextKit 2 kept every paragraph it laid out, so a key there grew
/// with the visited text. DECISIONS.md, "Source mode text system", has the measured numbers.
struct SourceTextView: UIViewRepresentable, Equatable {
    /// Only the start text. A change of it makes a new view.
    let markdown: String
    let sync: SourceTextSync

    /// SwiftUI would compare `markdown` with `String ==`: 250 ms on 100 MB of non-ASCII text. The text is not an input here.
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sync === rhs.sync
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sync: sync)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = SourceUITextView(usingTextLayoutManager: false)
        // Lays out only the part on screen. A far jump or a key at the end does not lay out the text before it.
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.delegate = context.coordinator
        // Figma CODE frame: monospace footnote. `scaledFont` scales from the default size, so pass the
        // footnote size at the default text size, not the current one, or the user's text size is applied twice.
        let defaultFootnoteSize = UIFont.preferredFont(
            forTextStyle: .footnote,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        ).pointSize
        textView.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .monospacedSystemFont(ofSize: defaultFootnoteSize, weight: .regular))
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = TokenColors.Text.primary
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.isFindInteractionEnabled = true
        textView.accessibilityIdentifier = "editor.source"
        textView.accessibilityLabel = context.environment.markdownEditorStrings.sourceEditor
        textView.text = sync.startText(for: markdown)
        sync.textView = textView
        return textView
    }

    /// Never read `markdown` here: `==` ignores it, so SwiftUI skips updates when only the text changed.
    /// An outside change makes a new view instead (`MarkdownEditor` checks the new text first).
    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.sync = sync
        sync.textView = textView
    }

    static func dismantleUIView(_ textView: UITextView, coordinator: Coordinator) {
        coordinator.cancelIdleFlush()
        // No binding write here: SwiftUI is updating views. `flush()` uses the saved text later.
        coordinator.sync.viewWillBeRemoved(textView)
        // Undo steps belong to this text. A new view with other text must not undo into it.
        textView.undoManager?.removeAllActions()
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var sync: SourceTextSync
        private var idleFlush: Task<Void, Never>?

        init(sync: SourceTextSync) {
            self.sync = sync
        }

        func textViewDidChange(_ textView: UITextView) {
            sync.didEdit()
            scheduleIdleFlush()
        }

        func cancelIdleFlush() {
            idleFlush?.cancel()
            idleFlush = nil
        }

        /// Writes back 1 s after the last key. Waits while IME text is marked: its text is not final yet.
        private func scheduleIdleFlush() {
            idleFlush?.cancel()
            idleFlush = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                idleFlush = nil
                if sync.textView?.markedTextRange != nil {
                    scheduleIdleFlush()
                } else {
                    await sync.flushInBackground()
                }
            }
        }
    }
}

/// A far caret jump (Find, ⌘↓, a selection set in code) must not animate:
/// each frame of the scroll lays out the text it passes, about 2 s for a jump to the end of 10 MB.
final class SourceUITextView: UITextView {
    /// Tests use a named pasteboard: reading the general one without a user action waits for permission.
    /// Read on each use: a stored default is not the general pasteboard in a view from `init(usingTextLayoutManager:)`.
    var pasteboard: UIPasteboard {
        get { namedPasteboard ?? .general }
        set { namedPasteboard = newValue }
    }
    private var namedPasteboard: UIPasteboard?

    private lazy var keyboard: KeyboardOverlap = {
        let keyboard = KeyboardOverlap()
        keyboard.onChange = { [weak self] in self?.setNeedsLayout() }
        return keyboard
    }()

    /// The last lines can scroll above the keyboard: the bottom inset is the part the keyboard covers.
    override func layoutSubviews() {
        super.layoutSubviews()
        let overlap = keyboard.overlap(with: self)
        guard contentInset.bottom != overlap else { return }
        contentInset.bottom = overlap
        verticalScrollIndicatorInsets.bottom = overlap
        if isFirstResponder { scrollRangeToVisible(selectedRange) }
    }

    override func scrollRangeToVisible(_ range: NSRange) {
        UIView.performWithoutAnimation {
            super.scrollRangeToVisible(range)
        }
    }

    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        let isFar = abs(contentOffset.y - self.contentOffset.y) > bounds.height
        super.setContentOffset(contentOffset, animated: animated && !isFar)
    }

    /// A copy from rich mode has a Markdown type next to the plain text.
    /// Source mode shows Markdown, so a paste takes that type first and keeps the syntax.
    /// A part of a code block pastes as its plain text: inside a code fence, escapes would stay in the code.
    override func paste(_ sender: Any?) {
        if pasteboard.contains(pasteboardTypes: [RichClipboardContent.codePartType]), let code = pasteboard.string {
            insertText(code)
            return
        }
        guard let data = pasteboard.data(forPasteboardType: RichClipboardContent.markdownType),
              let markdown = String(data: data, encoding: .utf8) else {
            super.paste(sender)
            return
        }
        insertText(markdown)
    }
}
