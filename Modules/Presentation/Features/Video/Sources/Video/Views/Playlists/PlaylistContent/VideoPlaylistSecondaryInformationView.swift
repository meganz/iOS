import MEGADesignToken
import SwiftUI

struct VideoPlaylistSecondaryInformationView: View {
    let videoConfig: VideoConfig
    let videosCount: String
    let totalDuration: String
    let isPublicLink: Bool
    
    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            secondaryText(text: videosCount)
            
            circleSeparatorImage
            
            secondaryText(text: totalDuration)
            
            circleSeparatorImage
                .opacity(isPublicLink ? 1 : 0)
            
            Image(uiImage: videoConfig.rowAssets.publicLinkImage)
                .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryTextColor)
                .opacity(isPublicLink ? 1 : 0)
        }
    }
    
    private func secondaryText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryTextColor)
    }
    
    private var circleSeparatorImage: some View {
        Image(uiImage: videoConfig.playlistContentAssets.headerView.image.dotSeparatorImage.withRenderingMode(.alwaysTemplate))
            .resizable()
            .frame(width: 4, height: 4)
            .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.secondaryIconColor)
    }
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videoConfig: .preview,
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: true
    )
}

#Preview {
    VideoPlaylistSecondaryInformationView(
        videoConfig: .preview,
        videosCount: "24 videos",
        totalDuration: "3:05:20",
        isPublicLink: false
    )
    .preferredColorScheme(.dark)
}
