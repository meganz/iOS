import MEGADesignToken
import SwiftUI

public struct SearchBarView: View {
    @Binding private var text: String
    @Binding private var isEditing: Bool

    var placeholder: String
    var cancelTitle: String
    var isDesignTokenEnabled: Bool
    
    public init(
        text: Binding<String>,
        isEditing: Binding<Bool>,
        placeholder: String,
        cancelTitle: String,
        isDesignTokenEnabled: Bool
    ) {
        self._text = text
        self._isEditing = isEditing
        self.placeholder = placeholder
        self.cancelTitle = cancelTitle
        self.isDesignTokenEnabled = isDesignTokenEnabled
    }
    
    public var body: some View {
        HStack {
            textField()
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(7)
                .padding(.horizontal, 25)
                .background(isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    SearchBarOverlayView(clearEnabled: !text.isEmpty, isDesignTokenEnabled: isDesignTokenEnabled) {
                        text = ""
                    }
                )
                .onTapGesture {
                    isEditing = true
                }
 
            if isEditing {
                SearchBarCancelButton(cancelTitle: cancelTitle, isDesignTokenEnabled: isDesignTokenEnabled) {
                    isEditing = false
                    text = ""
                    hideKeyboard()
                }
            }
        }
    }
    
    @ViewBuilder
    private func textField() -> some View {
        if isDesignTokenEnabled {
            textFieldForDesignToken()
        } else {
            textFieldForLegacyColor()
        }
    }
    
    @ViewBuilder
    private func textFieldForLegacyColor() -> some View {
        TextField(placeholder, text: $text)
    }
    
    @ViewBuilder
    private func textFieldForDesignToken() -> some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(TokenColors.Text.placeholder.swiftUI))
            .foregroundColor(TokenColors.Text.primary.swiftUI)
    }
}

private struct SearchBarOverlayView: View {
    var clearEnabled: Bool
    var isDesignTokenEnabled: Bool
    var action: () -> Void

    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.placeholder.swiftUI  : .gray)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
     
            if clearEnabled {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.placeholder.swiftUI : .gray)
                        .padding(.trailing, 8)
                })
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

private struct SearchBarCancelButton: View {
    var cancelTitle: String
    var isDesignTokenEnabled: Bool
    var action: () -> Void

    public var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(cancelTitle)
        })
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.placeholder.swiftUI : .secondary)
    }
}
