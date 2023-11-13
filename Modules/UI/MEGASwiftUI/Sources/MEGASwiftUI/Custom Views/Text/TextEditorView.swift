import SwiftUI

public struct TextEditorView: View {
    @Binding var text: String
    var placeholder: String?
    
    public init(text: Binding<String>, placeholder: String? = nil) {
        _text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        FocusableTextEditorView(text: $text, placeholder: placeholder)
    }
}

struct FocusableTextEditorView: View {
    @Binding var text: String
    var placeholder: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditorInputView(text: $text)
                .focused($isFocused)
                .onTapGesture {
                    isFocused = true
                }
            
            if text.isEmpty && !isFocused {
                PlaceholderView(text: placeholder)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct TextEditorInputView: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .foregroundColor(.primary)
            .font(.body)
            .overlay(Divider().background(Color.secondary.opacity(0.5)), alignment: .top)
            .overlay(Divider().background(Color.secondary.opacity(0.5)), alignment: .bottom)
    }
}

struct PlaceholderView: View {
    var text: String?
    var body: some View {
        Text(text ?? "")
            .foregroundColor(Color(UIColor.placeholderText))
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
    }
}
