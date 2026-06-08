import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct HomePromotionalDialogView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    static let detentHeight: CGFloat = 516
    let onExplore: () -> Void
    let onDismiss: () -> Void

    private var isIphoneLandscape: Bool {
        verticalSizeClass == .compact
    }

    var imageSize: CGFloat {
        isIphoneLandscape ? 80 : 120
    }

    var topPadding: CGFloat {
        isIphoneLandscape ? TokenSpacing._4 : TokenSpacing._11
    }

    var textsVerticalPadding: CGFloat {
        isIphoneLandscape ? TokenSpacing._4 : TokenSpacing._9
    }

    var body: some View {
            VStack(spacing: 0) {
            image
            ScrollView {
                texts
            }
            Divider()
            buttons
        }
        .background(
            TokenColors.Background.page.swiftUI
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .presentationDetents([.height(Self.detentHeight)])
        .presentationDragIndicator(.visible)
    }

    var image: some View {
        MEGAAssets.Image.homeRevampWhatsNew
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize, height: imageSize)
            .padding(.top, topPadding)
    }

    var texts: some View {
        VStack(spacing: TokenSpacing._3) {
            Text(Strings.Localizable.Home.PromotionalDialog.header)
                .font(.headline)
                .foregroundStyle(TokenColors.Button.brand.swiftUI)

            Text(Strings.Localizable.Home.PromotionalDialog.title)
                .font(.title.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Text(Strings.Localizable.Home.PromotionalDialog.subtitle)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.vertical, textsVerticalPadding)
    }

    var buttons: some View {
        VStack(spacing: TokenSpacing._5) {
            MEGAButton(
                Strings.Localizable.explore,
                type: .primary,
                action: onExplore
            )
            MEGAButton(
                Strings.Localizable.dismiss,
                type: .secondary,
                action: onDismiss
            )
        }
        .padding(.top, TokenSpacing._6)
        .padding(.horizontal, TokenSpacing._5)
        .padding(.bottom, TokenSpacing._5)
    }
}
