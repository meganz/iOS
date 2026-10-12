@testable import CloudDrive
import SwiftUI
import Testing
import UIKit

@MainActor
struct NewTextFileDialogLayoutTests {
    // A plain loop keeps the test id free of an argument suffix.
    private let cardWidths: [CGFloat] = [180, 300, 440]

    @Test func richTextRowIsAtLeast44PointsHigh() {
        let host = UIHostingController(rootView: NewTextFileRichTextRow(isChecked: .constant(false)))
        for width in cardWidths {
            let size = host.sizeThatFits(in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            #expect(size.height >= 44, "width \(width)")
        }
    }

    @Test func richTextRowSpansTheCardWidth() {
        // The whole row is the tap target, so it must fill the width the card gives it.
        let host = UIHostingController(rootView: NewTextFileRichTextRow(isChecked: .constant(true)))
        for width in cardWidths {
            let size = host.sizeThatFits(in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            #expect(size.width == width, "width \(width)")
        }
    }

    @Test func nameFieldReturnCallsSubmit() {
        var submitCount = 0
        let coordinator = NewTextFileNameField.Coordinator(onChange: { _ in }, onSubmit: { submitCount += 1 })

        let shouldReturn = coordinator.textFieldShouldReturn(UITextField())

        #expect(submitCount == 1)
        #expect(shouldReturn == false)
    }

    @Test func nameFieldEditingReportsTheText() {
        var received: [String] = []
        let coordinator = NewTextFileNameField.Coordinator(onChange: { received.append($0) }, onSubmit: {})
        let textField = UITextField()
        textField.text = "notes.md"

        coordinator.textDidChange(textField)

        #expect(received == ["notes.md"])
    }

    @Test func nameFieldKeepsTheCaretWhenTheRichTextBoxChangesTheName() async throws {
        let viewModel = NewTextFileDialogViewModel(onCreate: { _ in }, onCancel: {})
        let host = UIHostingController(rootView: NewTextFileDialogView(viewModel: viewModel, focusesOnAppear: true))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        let field = try #require(findTextField(in: host.view))
        try await waitUntil { field.isFirstResponder && caretOffset(of: field) == 0 }

        viewModel.isRichTextChecked = true
        try await waitUntil { field.text == ".md" }

        #expect(caretOffset(of: field) == 0)
        field.insertText("notes")
        #expect(field.text == "notes.md")
    }

    // MARK: - Helpers

    private func caretOffset(of field: UITextField) -> Int? {
        guard let range = field.selectedTextRange else { return nil }
        return field.offset(from: field.beginningOfDocument, to: range.start)
    }

    private func findTextField(in view: UIView) -> UITextField? {
        if let field = view as? UITextField { return field }
        return view.subviews.lazy.compactMap { findTextField(in: $0) }.first
    }

    /// SwiftUI applies focus and state changes on a later run loop pass.
    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<100 where !condition() {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(condition())
    }
}
