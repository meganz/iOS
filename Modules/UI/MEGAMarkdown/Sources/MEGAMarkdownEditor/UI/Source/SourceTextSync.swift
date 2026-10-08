import Foundation
import MEGAFoundation
import UIKit

/// Shares the source text view's text with `MarkdownEditor`. The view owns the text while the user types.
/// The editor calls `flush()` (mode switch, disappear, background). The view calls `flushInBackground()` after 1 s idle.
@MainActor
final class SourceTextSync {
    weak var textView: UITextView?
    private(set) var hasUnsavedEdits = false
    /// The text last read from or written to the binding.
    private(set) var lastSynced = ""
    /// The text of a removed view with unsaved edits. SwiftUI removes the view before `onDisappear`.
    private(set) var savedText: String?
    /// True after a flush for a switch to rich mode, until the editor sees that write come back.
    private var isSwitchWritePending = false
    /// Grows on every edit. The idle flush drops its result when an edit came in meanwhile.
    private var editCount = 0
    var onFlush: ((String) -> Void)?

    /// Writes the text to the binding when it has unsaved edits. Returns true when it wrote.
    /// Runs on the main thread (mode switch, disappear, background): about 26 ms at 10 MB.
    @discardableResult
    func flush() -> Bool {
        guard hasUnsavedEdits else { return false }
        guard let text = textView?.text ?? savedText else {
            MEGALog.log(level: .error, message: "[SourceTextSync] Unsaved edits lost, no text view and no saved text.")
            return false
        }
        write(Self.nativeString(text))
        return true
    }

    /// The idle flush. The text conversion runs off the main thread. The result is dropped if the user
    /// typed meanwhile: that edit starts its own idle flush.
    func flushInBackground() async {
        guard hasUnsavedEdits, let text = textView?.text ?? savedText else { return }
        let edit = editCount
        let native = await Self.nativeStringOffMain(text)
        guard hasUnsavedEdits, edit == editCount else { return }
        write(native)
    }

    private func write(_ text: String) {
        hasUnsavedEdits = false
        savedText = nil
        lastSynced = text
        onFlush?(text)
    }

    @concurrent
    private nonisolated static func nativeStringOffMain(_ text: String) async -> String {
        nativeString(text)
    }

    /// `UITextView.text` is a lazily bridged NSString. Comparing it with a native String walks it slowly
    /// (0.6 s at 10 MB), and every caller compares the binding. So the binding always gets native UTF-8.
    /// Foundation's UTF-8 export is about 10x faster than `makeContiguousUTF8()` on a bridged string.
    nonisolated static func nativeString(_ text: String) -> String {
        guard let data = (text as NSString).data(using: String.Encoding.utf8.rawValue) else {
            MEGALog.log(level: .warning, message: "[SourceTextSync] UTF-8 export failed, using the slow copy. utf16Length=\(text.utf16.count)")
            var native = text
            native.makeContiguousUTF8()
            return native
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// Flush before a switch to rich mode. The rich load starts right after, so the write must not start a second one.
    func flushForModeSwitch() {
        isSwitchWritePending = flush()
    }

    /// True once for the change a mode-switch flush wrote.
    func isModeSwitchWrite(_ newValue: String) -> Bool {
        let isOwn = isSwitchWritePending && newValue.hasSameBytes(as: lastSynced)
        isSwitchWritePending = false
        return isOwn
    }

    func didEdit() {
        hasUnsavedEdits = true
        editCount += 1
    }

    /// A new view shows `text`. Unsaved edits of a removed view win, so no key is lost.
    func startText(for markdown: String) -> String {
        if let savedText {
            self.savedText = nil
            return savedText
        }
        lastSynced = markdown
        hasUnsavedEdits = false
        return markdown
    }

    /// The binding changed from outside. The outside text wins over unsaved edits.
    func takeOutsideText(_ markdown: String) {
        lastSynced = markdown
        hasUnsavedEdits = false
        savedText = nil
    }

    func viewWillBeRemoved(_ textView: UITextView) {
        if hasUnsavedEdits {
            savedText = textView.text
        }
    }
}
