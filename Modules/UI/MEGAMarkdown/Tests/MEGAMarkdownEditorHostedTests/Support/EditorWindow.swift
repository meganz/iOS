import Foundation
@testable import MEGAMarkdownEditor
import Observation
import SwiftUI
import UIKit

/// Hosts the real `MarkdownEditor` in a window and records every write to its binding.
@MainActor
final class EditorWindow {
    @Observable
    @MainActor
    final class Model {
        var mode: MarkdownEditorMode
        var isShown = true
        /// Published like a real caller: every write re-renders the editor and compares the text.
        var text: String
        /// Every value the editor wrote to the binding.
        @ObservationIgnored var writes: [String] = []
        @ObservationIgnored let flusher = MarkdownEditorFlusher()

        init(text: String, mode: MarkdownEditorMode) {
            self.text = text
            self.mode = mode
        }

        var binding: Binding<String> {
            // SwiftUI calls a binding on the main thread.
            Binding(
                get: { MainActor.assumeIsolated { self.text } },
                set: { value in
                    MainActor.assumeIsolated {
                        self.text = value
                        self.writes.append(value)
                    }
                }
            )
        }
    }

    private struct Host: View {
        @Bindable var model: Model

        var body: some View {
            if model.isShown {
                MarkdownEditor(markdown: model.binding, mode: $model.mode, flusher: model.flusher)
                    .environment(\.richIdleDelay, EditorWindow.idleDelay)
            }
        }
    }

    /// The rich idle save waits this long here, so tests do not wait a second.
    static let idleDelay = Duration.milliseconds(100)

    let window: UIWindow
    let model: Model

    init(_ text: String, mode: MarkdownEditorMode = .source) {
        model = Model(text: text, mode: mode)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = UIHostingController(rootView: Host(model: model))
        // Never the key window: a row still takes the focus, but no software keyboard shows.
        // A real keyboard comes up at a different time in each run and makes the list shorter.
        window.isHidden = false
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }

    /// The source text view, or nil when none is shown.
    var sourceTextView: UITextView? {
        Self.sourceTextView(in: window)
    }

    private static func sourceTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView, textView.accessibilityIdentifier == "editor.source" {
            return textView
        }
        return view.subviews.lazy.compactMap { sourceTextView(in: $0) }.first
    }

    func waitForSourceTextView() async throws -> UITextView {
        try await waitForValue("the source text view") { sourceTextView }
    }

    /// The rich row text views on screen, top to bottom. Hidden views of reused cells are skipped.
    var richTextViews: [RichTextView] {
        var found: [RichTextView] = []
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            guard !view.isHidden else { continue }
            if let textView = view as? RichTextView { found.append(textView) }
            pending.append(contentsOf: view.subviews)
        }
        return found.sorted { $0.convert($0.bounds, to: nil).minY < $1.convert($1.bounds, to: nil).minY }
    }

    /// Rich mode loads off the main thread, so wait for its row with `text`.
    func waitForRichRow(_ text: String) async throws -> RichTextView {
        try await waitForValue("a rich row with the text \"\(text)\"") { richTextViews.first { $0.text == text } }
    }

    /// Puts the caret at the end of a rich row and types like the keyboard: it asks the delegate first.
    func typeAtEnd(_ text: String, into textView: RichTextView) {
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: (textView.text as NSString).length, length: 0)
        let range = textView.selectedRange
        if textView.delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true {
            textView.insertText(text)
        }
    }

    /// The accessibility identifiers in the window, read through the accessibility tree.
    /// SwiftUI text is not a UIView, but its accessibility element carries the identifier.
    var accessibilityIdentifiers: [String] {
        var result: [String] = []
        var pending: [NSObject] = [window]
        while let element = pending.popLast() {
            // SwiftUI elements answer `accessibilityIdentifier` without declaring the protocol.
            let getter = NSSelectorFromString("accessibilityIdentifier")
            if element.responds(to: getter), let identifier = element.value(forKey: "accessibilityIdentifier") as? String, !identifier.isEmpty {
                result.append(identifier)
            }
            if let view = element as? UIView { pending.append(contentsOf: view.subviews) }
            let count = element.accessibilityElementCount()
            if count != NSNotFound, count > 0 {
                pending.append(contentsOf: (0..<count).compactMap { element.accessibilityElement(at: $0) as? NSObject })
            }
            pending.append(contentsOf: (element.accessibilityElements as? [NSObject]) ?? [])
        }
        return result
    }

    func waitForIdentifier(_ identifier: String) async throws {
        try await waitUntil("the accessibility identifier \(identifier)") { accessibilityIdentifiers.contains(identifier) }
    }

    static func settle(_ milliseconds: Int = 100) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
    }
}
