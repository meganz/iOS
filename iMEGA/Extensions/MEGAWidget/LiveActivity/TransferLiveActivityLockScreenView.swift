import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import Transfer
import WidgetKit

@available(iOS 16.2, *)
struct TransferLiveActivityLockScreenView: View {
    let viewState: TransferLiveActivityViewState

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            MEGAAssets.Image.megaLogoText
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 16)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._3)
            HStack {
                viewState.statusIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(viewState.statusIconTint)
                Text(viewState.statusText)
                    .font(.liveActivityStatus)
                    .tracking(-0.4)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
                Text(viewState.percentageText)
                    .font(.liveActivityPercentageSm)
                    .tracking(-0.4)
                    .foregroundStyle(viewState.tintColor)
            }
            .padding(.horizontal, TokenSpacing._5)

            ProgressView(value: viewState.progressFraction)
                .progressViewStyle(CapsuleProgressViewStyle(tint: viewState.tintColor, height: 12))
                .padding(.horizontal, TokenSpacing._5)

            HStack {
                Text(viewState.fileCountText)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
                Text(viewState.speed)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .padding(.horizontal, TokenSpacing._7)
        }
        .padding(.vertical, TokenSpacing._5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewState.accessibilityDescription)
    }
}
