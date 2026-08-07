import MEGAL10n

public extension TextFieldAlertViewModel {
    /// Asks for the decryption key of a public link that was shared without it. Present it with
    /// `View.alert(isPresented:_:)`.
    /// - Parameters:
    ///   - message: Explanation shown under the title. Owned by the caller because the copy
    ///   differs per link type.
    ///   - placeholder: Hint text of the key field.
    ///   - confirm: Called with the entered key when the affirmative button is tapped.
    ///   - cancel: Called when the alert is dismissed without a key.
    static func decryptionKey(
        message: String,
        placeholder: String,
        confirm: @MainActor @escaping (String) -> Void,
        cancel: @MainActor @escaping () -> Void
    ) -> Self {
        Self(
            title: Strings.Localizable.decryptionKeyAlertTitle,
            placeholderText: placeholder,
            affirmativeButtonTitle: Strings.Localizable.decrypt,
            affirmativeButtonInitiallyEnabled: false,
            destructiveButtonTitle: Strings.Localizable.cancel,
            message: message,
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
    }
}
