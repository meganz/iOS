import MEGADesignToken
import SwiftUI

/// Provides a custom text editor using UITextView with a 'Done' key on the keyboard.
/// When 'Done' is tapped, the keyboard is dismissed and new line entries are disabled.
/// This approach allows customization of the returnKeyType to 'Done' and ensures single-line input, addressing limitations in SwiftUI's TextEditor for iOS 15 and 16.
public struct TextEditorWithDoneKeyboardView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    
    public init(text: Binding<String>, isFocused: Binding<Bool>) {
        _text = text
        _isFocused = isFocused
    }

    final public class Coordinator: NSObject, UITextViewDelegate {
        let parent: TextEditorWithDoneKeyboardView
        
        init(_ parent: TextEditorWithDoneKeyboardView) {
            self.parent = parent
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        public func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }
        
        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }
        
        public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Detect the return key, dismiss the keyboard and prevent adding a newline
            guard text == "\n" else { return true }
            textView.resignFirstResponder()
            return false
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.font = .preferredFont(forTextStyle: .callout)
        textView.returnKeyType = .done
        textView.backgroundColor = .clear
        textView.showsVerticalScrollIndicator = false
        textView.textColor = TokenColors.Text.primary
        return textView
    }
    
    public func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
