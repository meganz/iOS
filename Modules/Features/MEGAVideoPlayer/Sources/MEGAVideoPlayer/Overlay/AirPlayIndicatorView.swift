import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct AirPlayIndicatorView: View {
    private enum Constants {
        static let iconSize: CGFloat = 96
    }

    var body: some View {
        VStack(spacing: TokenSpacing._6) {
            MEGAAssets.Image.monoAirplayMediumThinOutline
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)

            VStack(spacing: TokenSpacing._2) {
                Text(Strings.Localizable.VideoPlayer.AirPlay.BottomSheet.title)
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)

                Text(Strings.Localizable.VideoPlayer.AirPlay.Indicator.playingOnDevice)
                    .font(.subheadline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(TokenSpacing._7)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AirPlayIndicatorView()
    }
    .preferredColorScheme(.dark)
}
