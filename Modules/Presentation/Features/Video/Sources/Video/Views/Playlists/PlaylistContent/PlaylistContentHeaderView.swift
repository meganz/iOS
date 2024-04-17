import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PlaylistContentHeaderView: View {
    let videoConfig: VideoConfig
    let imageContainers: [any ImageContaining]
    let title: String
    let videosCount: String
    let totalDuration: String
    let onTapAddButton: () -> Void
    let onTapPlayButton: () -> Void
    
    private var sampleImage: Image {
        PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VideoPlaylistThumbnailView(videoConfig: videoConfig, imageContainers: [
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail)
            ])
            .frame(width: 142, height: 80)
            
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.primaryTextColor)
                
                secondaryTextsContent
                
                buttonsContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(videoConfig.playlistContentAssets.headerView.color.pageBackgroundColor)
    }
    
    private var secondaryTextsContent: some View {
        HStack(spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            circleSeparatorImage
            
            secondaryText(text: totalDuration)
            
            circleSeparatorImage
            
            Image(uiImage: videoConfig.rowAssets.publicLinkImage)
                .font(.system(size: 12))
                .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryTextColor)
        }
    }
    
    private func secondaryText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .font(.system(size: 12))
            .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryTextColor)
    }
    
    private var circleSeparatorImage: some View {
        Image(uiImage: videoConfig.playlistContentAssets.headerView.image.dotSeparatorImage.withRenderingMode(.alwaysTemplate))
            .resizable()
            .frame(width: 4, height: 4)
            .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryIconColor)
    }
    
    private var buttonsContent: some View {
        HStack(spacing: TokenSpacing._5) {
            addButton
            playButton
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        if isDesignTokenEnabled {
            PillView(
                viewModel: .init(
                    title: "Add", // CC-6824
                    icon: .leading(Image(uiImage: videoConfig.playlistContentAssets.headerView.image.addButtonImage.withRenderingMode(.alwaysTemplate))),
                    foreground: TokenColors.Text.accent.swiftUI,
                    background: TokenColors.Button.secondary.swiftUI,
                    shape: .capsule
                )
            )
            .onTapGesture { onTapAddButton() }
        } else {
            IconButton(
                image: Image(uiImage: videoConfig.playlistContentAssets.headerView.image.addButtonImage),
                title: "Add", // CC-6824
                tintColor: videoConfig.playlistContentAssets.headerView.color.buttonTintColor,
                action: { onTapAddButton() }
            )
        }
    }
    
    private var playButton: some View {
        PillView(
            viewModel: .init(
                title: "Play", // CC-6824
                icon: .leading(Image(uiImage: videoConfig.playlistContentAssets.headerView.image.playButtonImage.withRenderingMode(.alwaysTemplate))),
                foreground: isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : videoConfig.colorAssets.whiteColor,
                background: isDesignTokenEnabled ? TokenColors.Button.primary.swiftUI : videoConfig.playlistContentAssets.headerView.color.buttonTintColor,
                shape: .capsule
            )
        )
        .onTapGesture { onTapPlayButton() }
    }
}

#Preview {
    PlaylistContentHeaderView(
        videoConfig: .preview,
        imageContainers: [],
        title: "Magic of Disney’s Animal Kingdom",
        videosCount: "24 Videos",
        totalDuration: "3:05:20",
        onTapAddButton: {},
        onTapPlayButton: {}
    )
}

#Preview {
    PlaylistContentHeaderView(
        videoConfig: .preview,
        imageContainers: [],
        title: "Magic of Disney’s Animal Kingdom",
        videosCount: "24 Videos",
        totalDuration: "3:05:20",
        onTapAddButton: {},
        onTapPlayButton: {}
    )
    .preferredColorScheme(.dark)
}
