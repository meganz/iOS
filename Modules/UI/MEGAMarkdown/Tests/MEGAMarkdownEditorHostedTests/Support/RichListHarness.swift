import MEGAMarkdown
@testable import MEGAMarkdownEditor
import SwiftUI
import UIKit

/// Rich mode of a Markdown text in a window: the model, the adapter and the row list.
@MainActor
final class RichListHarness {
    struct HarnessError: Error, CustomStringConvertible {
        let description: String
    }

    private struct Root: View {
        let adapter: RichRowAdapter
        let layoutDirection: LayoutDirection
        let colorScheme: ColorScheme
        let dynamicType: DynamicTypeSize

        var body: some View {
            RichEditorView(adapter: adapter, baseURL: nil)
                .environment(\.layoutDirection, layoutDirection)
                .environment(\.colorScheme, colorScheme)
                .environment(\.dynamicTypeSize, dynamicType)
        }
    }

    let adapter: RichRowAdapter
    let window: UIWindow
    private let hosting: UIHostingController<Root>
    private let dynamicType: DynamicTypeSize

    var model: RichEditorModel { adapter.model }
    var list: MarkdownRowList { adapter.list }

    init(
        _ markdown: String,
        width: CGFloat = 390,
        height: CGFloat = 700,
        layoutDirection: LayoutDirection = .leftToRight,
        colorScheme: ColorScheme = .light,
        dynamicType: DynamicTypeSize = .large,
        isKey: Bool = false
    ) throws {
        guard case .loaded(let load) = RichEditorLoad.make(markdown) else {
            throw HarnessError(description: "The markdown did not load as a rich document")
        }
        self.dynamicType = dynamicType
        adapter = RichRowAdapter(model: RichEditorModel(editor: load.editor), load: load)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        hosting = UIHostingController(rootView: Root(adapter: adapter, layoutDirection: layoutDirection, colorScheme: colorScheme, dynamicType: dynamicType))
        window.rootViewController = hosting
        // Not key by default: a row still takes the focus, but no software keyboard shows.
        // A real keyboard comes up at a different time in each run and makes the list shorter.
        if isKey {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
        window.layoutIfNeeded()
        list.view.layoutIfNeeded()
    }

    /// Changes the SwiftUI environment of the list, like a host that switches language or appearance.
    func setEnvironment(layoutDirection: LayoutDirection, colorScheme: ColorScheme) {
        hosting.rootView = Root(adapter: adapter, layoutDirection: layoutDirection, colorScheme: colorScheme, dynamicType: dynamicType)
    }

    /// Changes the window size, like a rotation.
    func resize(width: CGFloat, height: CGFloat) {
        window.frame = CGRect(x: 0, y: 0, width: width, height: height)
        window.layoutIfNeeded()
        list.view.layoutIfNeeded()
    }

    func close() {
        window.endEditing(true)
        window.isHidden = true
        window.rootViewController = nil
    }

    func textView(row: Int) -> RichTextView? {
        adapter.textView(forItem: adapter.items(forRow: row).lowerBound)
    }

    /// Puts the caret like a tap in the row: the editor gets the focus, then the model the caret.
    func focus(row: Int, caret: Int) {
        model.setFocused(true)
        model.select(.caret(RichPosition(blockIndex: row, offset: caret)))
    }

    var focusedTextView: RichTextView? {
        var pending: [UIView] = [window]
        while let view = pending.popLast() {
            if let textView = view as? RichTextView, textView.isFirstResponder { return textView }
            pending.append(contentsOf: view.subviews)
        }
        return nil
    }

    /// Types like the keyboard: it asks the delegate first.
    func type(_ text: String) throws {
        guard let textView = focusedTextView else { throw HarnessError(description: "No row has the focus, so there is nothing to type into") }
        let range = textView.selectedRange
        if textView.delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true {
            textView.insertText(text)
        }
    }

    /// Lets SwiftUI and the list run their layout passes.
    func settle(_ milliseconds: Int = 50) async throws {
        try await Task.sleep(for: .milliseconds(milliseconds))
        window.layoutIfNeeded()
        list.view.layoutIfNeeded()
    }

    /// Waits for `condition` with the shared helper, and runs the layout passes on every poll.
    func waitUntil(_ what: String = "the list condition", _ condition: () -> Bool) async throws {
        try await MEGAMarkdownEditorHostedTests.waitUntil(what) {
            window.layoutIfNeeded()
            list.view.layoutIfNeeded()
            return condition()
        }
    }
}

extension RichListHarness {
    /// The selection layer of the list. `RichEditorRowList.makeCoordinator()` makes it.
    var selectionController: CrossBlockSelectionController? {
        adapter.selectionHandler as? CrossBlockSelectionController
    }
}
