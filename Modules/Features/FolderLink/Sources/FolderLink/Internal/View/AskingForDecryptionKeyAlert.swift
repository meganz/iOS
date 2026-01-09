import MEGAL10n
import MEGASwiftUI
import SwiftUI

extension View {
    func askingForDecryptionKeyAlert(
        isPresented: Binding<Bool>,
        confirm: @MainActor @escaping (String) -> Void,
        cancel: @MainActor @escaping () -> Void
    ) -> some View {
        let viewModel = TextFieldAlertViewModel(
            title: Strings.Localizable.decryptionKeyAlertTitle,
            placeholderText: Strings.Localizable.decryptionKey,
            affirmativeButtonTitle: Strings.Localizable.decrypt,
            affirmativeButtonInitiallyEnabled: false,
            destructiveButtonTitle: Strings.Localizable.cancel,
            message: Strings.Localizable.decryptionKeyAlertMessage,
            action: { text in
                if let text {
                    confirm(text)
                } else {
                    cancel()
                }
            },
            validator: { text in
                if let text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    nil
                } else {
                    TextFieldAlertError(title: "", description: "")
                }
            }
        )
        
        return alert(isPresented: isPresented, viewModel)
    }
}
