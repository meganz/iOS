import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Empty state of an album link: the album behind the link resolved, but holds no photos.
///
/// The revamped layout is the Empty state component of the link revamp design -- the glass album
/// illustration over a single Callout line -- while the flag is off keeps the layout the album link has always shown.
struct AlbumLinkEmptyView: View {
    private enum Constants {
        static let imageSize: CGFloat = 120
        static let contentMaxWidth: CGFloat = 414
    }

    let isLinkRevampEnabled: Bool

    var body: some View {
        if isLinkRevampEnabled {
            revampedContent
        } else {
            legacyContent
        }
    }

    private var revampedContent: some View {
        VStack(spacing: TokenSpacing._7) {
            MEGAAssets.Image.glassAlbum
                .resizable()
                .scaledToFit()
                .frame(width: Constants.imageSize, height: Constants.imageSize)
                // Decorative: the line below it says everything the illustration does, and left
                // visible to VoiceOver it would only read out the asset's own name.
                .accessibilityHidden(true)

            Text(Strings.Localizable.CameraUploads.Albums.Empty.title)
                .font(.callout)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, TokenSpacing._9)
        .frame(maxWidth: Constants.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var legacyContent: some View {
        ContentUnavailableView {
            MEGAAssets.Image.allPhotosEmptyState
        } description: {
            Text(Strings.Localizable.CameraUploads.Albums.Empty.title)
                .font(.body)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview("Link revamp") {
    AlbumLinkEmptyView(isLinkRevampEnabled: true)
}

#Preview("Legacy") {
    AlbumLinkEmptyView(isLinkRevampEnabled: false)
}
