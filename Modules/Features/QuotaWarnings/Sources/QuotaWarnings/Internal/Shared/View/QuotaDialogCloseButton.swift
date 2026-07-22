import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct QuotaDialogCloseButton: View {
    let onClose: () -> Void

    var body: some View {
        Button(action: onClose) {
            if #available(iOS 26.0, *) {
                icon
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                icon
            }
        }
        .accessibilityLabel(Strings.Localizable.close)
    }
    
    private var icon: some View {
        MEGAAssets.Image.x
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .padding(10)
    }
}

#Preview {
    QuotaDialogCloseButton(onClose: {})
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
}
