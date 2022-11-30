import SwiftUI

public struct TextEditorView: View {
    @Binding var text: String
    var placeholder: String?
    var isShowingPlaceholder: Bool?
    
    public init(text: Binding<String>, placeholder: String? = nil, isShowingPlaceholder: Bool? = nil) {
        _text = text
        self.placeholder = placeholder
        self.isShowingPlaceholder = isShowingPlaceholder
    }
    
    public var body: some View {
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
