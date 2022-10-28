import SwiftUI

public struct SearchBarView: View {
    @Binding private var text: String
    @Binding private var isEditing: Bool

    var placeholder: String
    var cancelTitle: String
    
    public init(text: Binding<String>, isEditing: Binding<Bool>, placeholder: String, cancelTitle: String) {
        self._text = text
        self._isEditing = isEditing
        self.placeholder = placeholder
        self.cancelTitle = cancelTitle
    }
    
    public var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    SearchBarOverlayView(clearEnabled: !text.isEmpty) {
                        text = ""
                    }
                )
                .onTapGesture {
                    isEditing = true
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
}

private struct SearchBarOverlayView: View {
    var clearEnabled: Bool
    var action: () -> Void

    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
     
            if clearEnabled {
                Button(action: {
                    action()
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
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
        }) {
            Text(cancelTitle)
        }
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.secondary)
        .padding(.trailing, 10)
        .transition(.move(edge: .trailing))
        .animation(.default)
    }
}
