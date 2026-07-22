import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct QuotaDialogErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: TokenSpacing._7) {
                    VStack(spacing: TokenSpacing._7) {
                        MEGAAssets.Image.glassNoCloud
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        VStack(spacing: TokenSpacing._5) {
                            Text(Strings.Localizable.QuotaWarning.Error.title)
                                .font(.title3.bold())
                                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                            Text(Strings.Localizable.QuotaWarning.Error.subtitle)
                                .font(.callout)
                                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        }
                        .multilineTextAlignment(.center)
                    }
                    MEGAButton(
                        Strings.Localizable.QuotaWarning.Error.Button.tryAgain,
                        type: .secondary,
                        action: onRetry
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
    }
}

#Preview {
    QuotaDialogErrorView(onRetry: {})
}
