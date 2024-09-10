import MEGADesignToken
import SwiftUI

public struct FocusableTextFieldView: View {
    let placeholder: String
    @Binding var text: String
    var appearFocused: Bool = false
    let clearButtonMode: UITextField.ViewMode
    
    public init(placeholder: String,
                text: Binding<String>,
                appearFocused: Bool,
                clearButtonMode: UITextField.ViewMode = .never) {
        self.placeholder = placeholder
        _text = text
        self.appearFocused = appearFocused
        self.clearButtonMode = clearButtonMode
    }
    
    public var body: some View {
        FocusableTextField(placeholder: placeholder,
                           text: $text,
                           appearFocused: appearFocused,
                           clearButtonMode: clearButtonMode)
    }
    
    struct FocusableTextField: View {
        let placeholder: String
        @Binding var text: String
        @FocusState var focused: Bool
        let appearFocused: Bool
        let clearButtonMode: UITextField.ViewMode

        var body: some View {
            textField
                .focused($focused)
                .onAppear {
                    if clearButtonMode != .never {
                        UITextField.appearance().clearButtonMode = clearButtonMode
                    }
                    focused = appearFocused
                }
        }
        
        @ViewBuilder
        var textField: some View {
            TextField(
                "", text: $text, prompt: Text(placeholder).foregroundColor(TokenColors.Text.placeholder.swiftUI)
            )
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }
}
