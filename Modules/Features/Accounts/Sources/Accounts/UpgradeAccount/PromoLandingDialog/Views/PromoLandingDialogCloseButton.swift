import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct PromoLandingDialogCloseButton: View {
    let dismissAction: @MainActor () -> Void

    var body: some View {
        Button {
            dismissAction()
        } label: {
            MEGAAssets.Image.x
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .glassCircle()
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, TokenSpacing._3)
        .accessibilityLabel(Strings.Localizable.close)
    }
}

#Preview {
    PromoLandingDialogCloseButton(dismissAction: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(TokenColors.Background.page.swiftUI)
}
