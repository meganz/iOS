import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

/// Unavailable state of an album link. It is only reached with the link revamp flag on: without it
/// the album link reports the same failure as an alert.
struct AlbumLinkUnavailableView: View {
    private enum Constants {
        /// Not localised, as in the file link: it is the brand, not a word.
        static let brandTitle = "MEGA"
    }

    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            fullScreenContent
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                // The design draws the bar as transparent page background, with only the close
                // button carrying a glass capsule.
                .hideNavigationToolbarBackground()
                .toolbar { toolbarContent }
        }
        .tint(TokenColors.Icon.primary.swiftUI)
    }

    /// Centres the unavailable state on the whole screen rather than on the area below the
    /// navigation bar, which is transparent here. Same treatment as the file link.
    private var fullScreenContent: some View {
        GeometryReader { proxy in
            let topOffset = proxy.frame(in: .global).minY

            LinkUnavailableContentView(reason: .generic, copy: .albumLink)
                .frame(width: proxy.size.width, height: proxy.size.height + topOffset)
                .offset(y: -topOffset)
        }
        .ignoresSafeArea()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            closeButton
        }

        ToolbarItem(placement: .principal) {
            titleView
        }
    }

    private var titleView: some View {
        VStack {
            Text(Constants.brandTitle)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)

            Text(Strings.Localizable.albumLink)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .lineLimit(1)
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            closeIcon
        }
        .accessibilityLabel(Strings.Localizable.close)
    }

    /// From iOS 26 the toolbar puts the icon in a glass capsule of its own, so the padding that
    /// gives it a tappable area on earlier versions would double up.
    @ViewBuilder
    private var closeIcon: some View {
        let icon = MEGAAssets.Image.x
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)

        if #available(iOS 26.0, *) {
            icon
        } else {
            icon.padding(10)
        }
    }
}

#Preview {
    AlbumLinkUnavailableView(onClose: {})
}
