import MEGADesignToken
import SwiftUI

public struct SearchBarView: View {
    @Binding private var text: String
    @Binding private var isEditing: Bool

    var placeholder: String
    var cancelTitle: String
    
    @FocusState private var isSearchFieldFocused: Bool
    
    public init(
        text: Binding<String>,
        isEditing: Binding<Bool>,
        placeholder: String,
        cancelTitle: String
    ) {
        self._text = text
        self._isEditing = isEditing
        self.placeholder = placeholder
        self.cancelTitle = cancelTitle
    }
    
    public var body: some View {
        HStack {
            textField()
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(7)
                .padding(.horizontal, 25)
                .background(TokenColors.Background.surface2.swiftUI)
                .cornerRadius(8)
                .overlay(
                    SearchBarOverlayView(clearEnabled: !text.isEmpty) {
                        text = ""
                    }
                )
                .focused($isSearchFieldFocused)
                .onChange(of: isSearchFieldFocused) { focused in
                    isEditing = focused
                }
 
            if isEditing {
                SearchBarCancelButton(cancelTitle: cancelTitle) {
                    isEditing = false
                    text = ""
                    hideKeyboard()
                }
            }
        }
    }
    
    @ViewBuilder
    private func textField() -> some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(TokenColors.Text.placeholder.swiftUI))
            .foregroundColor(TokenColors.Text.primary.swiftUI)
    }
}

private struct SearchBarOverlayView: View {
    var clearEnabled: Bool
    var action: () -> Void

    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(TokenColors.Text.placeholder.swiftUI)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
     
            if clearEnabled {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(TokenColors.Text.placeholder.swiftUI)
                        .padding(.trailing, 8)
                })
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

private struct SearchBarCancelButton: View {
    var cancelTitle: String
    var action: () -> Void

    public var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(cancelTitle)
        })
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(TokenColors.Text.placeholder.swiftUI)
    }
}
