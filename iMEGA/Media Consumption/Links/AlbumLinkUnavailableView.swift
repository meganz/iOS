import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// Unavailable state of an album link.
///
/// The revamped layout is the shared unavailable page the file link and the folder link show, while
/// the flag is off keeps the copy the album link has always used for an invalid link -- which used
/// to be shown as an alert over the album content, and was dropped by SwiftUI once the screen's
/// other modals moved onto the same view.
struct AlbumLinkUnavailableView: View {
    private enum Constants {
        /// Not localised, as in the file link: it is the brand, not a word.
        static let brandTitle = "MEGA"
        static let legacyImageWidth: CGFloat = 200
        static let legacyImageHeight: CGFloat = 120
        static let legacyContentMaxWidth: CGFloat = 414
    }

    let isLinkRevampEnabled: Bool
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            unavailableContent
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar { toolbarContent }
        }
        .tint(TokenColors.Icon.primary.swiftUI)
    }

    @ViewBuilder
    private var unavailableContent: some View {
        if isLinkRevampEnabled {
            fullScreenContent
        } else {
            legacyContent
        }
    }

    /// Centres the unavailable state on the whole screen rather than on the area below the
    /// navigation bar, so that it stays optically centred under the translucent bar. Same treatment
    /// as the file link.
    private var fullScreenContent: some View {
        GeometryReader { proxy in
            let topOffset = proxy.frame(in: .global).minY

            LinkUnavailableContentView(reason: .generic, copy: .albumLink)
                .frame(width: proxy.size.width, height: proxy.size.height + topOffset)
                .offset(y: -topOffset)
        }
        .ignoresSafeArea()
    }

    /// The pre-revamp copy, laid out the way the legacy file and folder links lay their unavailable
    /// state out: the same illustration over the title and the reason.
    private var legacyContent: some View {
        VStack(spacing: TokenSpacing._7) {
            Image(uiImage: MEGAAssets.UIImage.invalidLink)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.legacyImageWidth, height: Constants.legacyImageHeight)

            VStack(spacing: TokenSpacing._5) {
                Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.title)
                    .font(.headline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.message)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, TokenSpacing._9)
        .frame(maxWidth: Constants.legacyContentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
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

    /// The revamp names the brand above the kind of link. The legacy screen only ever showed the
    /// kind of link, so that is what stays there while the flag is off.
    @ViewBuilder
    private var titleView: some View {
        if isLinkRevampEnabled {
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
        } else {
            Text(Strings.Localizable.albumLink)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
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

#Preview("Link revamp") {
    AlbumLinkUnavailableView(isLinkRevampEnabled: true, onClose: {})
}

#Preview("Legacy") {
    AlbumLinkUnavailableView(isLinkRevampEnabled: false, onClose: {})
}
