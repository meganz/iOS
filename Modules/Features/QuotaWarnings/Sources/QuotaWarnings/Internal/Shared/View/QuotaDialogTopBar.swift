import MEGADesignToken
import SwiftUI

struct QuotaDialogTopBar: View {
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            QuotaDialogCloseButton(onClose: onClose)
            Spacer(minLength: 0)
        }
        .frame(height: TokenSpacing._12)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.top, TokenSpacing._5)
        .padding(.bottom, TokenSpacing._5)
        .background(background)
    }

    private var background: Color {
        if #available(iOS 26.0, *) {
            Color.clear
                
        } else {
            TokenColors.Background.surface1.swiftUI
        }
    }
}

#Preview {
    QuotaDialogTopBar(onClose: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(TokenColors.Background.page.swiftUI)
}
