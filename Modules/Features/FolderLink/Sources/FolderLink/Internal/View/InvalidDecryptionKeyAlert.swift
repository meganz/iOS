import MEGAL10n
import SwiftUI

extension View {
    nonisolated func invalidDecryptionKeyAlert(isPresented: Binding<Bool>, action: @MainActor @escaping () -> Void) -> some View {
        alert(
            Strings.Localizable.decryptionKeyNotValid,
            isPresented: isPresented, actions: {
                Button(Strings.Localizable.ok, action: action)
            }
        )
    }
}
