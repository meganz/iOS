import MEGAAssets
import MEGADesignToken
import SwiftUI

/// The preview area of the file link screen: the file's image for media, the file type icon for
/// everything else.
struct FileLinkPreviewView: View {
    private enum Constants {
        /// The height the design draws, applied as a ceiling rather than as a fixed height: in
        /// landscape the screen is not tall enough for both this and the file's details, and the
        /// details are the ones that must not be squeezed.
        static let maxHeight: CGFloat = 298
        static let maxIconSize: CGFloat = 120
        static let playButtonSize: CGFloat = 56
    }

    let preview: FileLinkContentViewModel.Preview

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: Constants.maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.medium))
            .padding(TokenSpacing._5)
    }

    @ViewBuilder
    private var content: some View {
        switch preview {
        case let .fileTypeIcon(image):
            ZStack {
                TokenColors.Background.surface1.swiftUI

                // The icon shrinks with the area rather than being cropped by it, so that a short
                // preview area in landscape still shows the whole icon.
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: Constants.maxIconSize, maxHeight: Constants.maxIconSize)
            }
        case let .media(image, videoDuration):
            Color.clear
                .overlay {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .overlay {
                    if let videoDuration {
                        videoOverlay(duration: videoDuration)
                    }
                }
        }
    }

    /// The play button does not play anything here: tapping the preview leads to the player, so it is
    /// there to say the file is a video.
    private func videoOverlay(duration: String) -> some View {
        ZStack {
            Image(uiImage: MEGAAssets.UIImage.playButton)
                .resizable()
                .frame(width: Constants.playButtonSize, height: Constants.playButtonSize)
                .accessibilityHidden(true)

            Text(duration)
                .font(.caption2)
                .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                .padding(.horizontal, TokenSpacing._2)
                .padding(.vertical, TokenSpacing._1)
                .background(TokenColors.Background.surfaceTransparent.swiftUI)
                .clipShape(RoundedRectangle(cornerRadius: TokenRadius.small))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(TokenSpacing._3)
        }
    }
}

#Preview("File type icon") {
    FileLinkPreviewView(preview: .fileTypeIcon(MEGAAssets.Image.image(forFileName: "roadmap.pdf")))
        .background(TokenColors.Background.page.swiftUI)
}

#Preview("Video") {
    FileLinkPreviewView(
        preview: .media(image: MEGAAssets.Image.filetypeGeneric, videoDuration: "2:50")
    )
    .background(TokenColors.Background.page.swiftUI)
}
