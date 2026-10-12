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
}
