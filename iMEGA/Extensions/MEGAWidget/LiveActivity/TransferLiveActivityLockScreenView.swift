import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import Transfer
import WidgetKit

@available(iOS 16.2, *)
struct TransferLiveActivityLockScreenView: View {
    let state: TransferLiveActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            MEGAAssets.Image.megaLogoText
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 16)
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._3)
            HStack {
                state.statusIcon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(state.statusIconTint)
                Text(state.statusText)
                    .font(.liveActivityStatus)
                    .tracking(-0.4)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
                Text(state.percentageText)
                    .font(.liveActivityPercentageSm)
                    .tracking(-0.4)
                    .foregroundStyle(state.tintColor)
            }
            .padding(.horizontal, TokenSpacing._5)

            ProgressView(value: state.progressFraction)
                .progressViewStyle(CapsuleProgressViewStyle(tint: state.tintColor, height: 12))
                .padding(.horizontal, TokenSpacing._5)

            HStack {
                Text(state.fileCountText)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Spacer()
                Text(state.formattedSpeed)
                    .font(.liveActivityCaptionMd)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .padding(.horizontal, TokenSpacing._7)
        }
        .padding(.vertical, TokenSpacing._5)
    }
}
