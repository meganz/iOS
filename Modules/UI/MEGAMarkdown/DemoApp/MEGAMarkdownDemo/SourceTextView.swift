import SwiftUI
import UIKit

/// Shows the raw Markdown text, read-only, in a monospaced font.
struct SourceTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        // TextKit 1 with non-contiguous layout lays out only the visible part, so big files open fast.
        let textView = UITextView(usingTextLayoutManager: false)
        textView.layoutManager.allowsNonContiguousLayout = true
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.text = text
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }
}
