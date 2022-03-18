
import SwiftUI

@available(iOS 14.0, *)
struct TextEditorView: View {
    @Binding var text: String
    var placeholder: String?
    var isShowingPlaceholder: Bool?
    var body: some View {
        TextEditor(text: $text)
            .foregroundColor(isShowingPlaceholder ?? false ? Color(.placeholderText) : .primary)
            .font(.body)
            .overlay(Divider().background(Color.secondary.opacity(0.5)), alignment: .top)
            .overlay(Divider().background(Color.secondary.opacity(0.5)), alignment: .bottom)
            .onTapGesture {
                if (placeholder != nil) && text == placeholder {
                    text = ""
                }
            }
    }
}
