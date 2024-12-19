import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct VideoPlaylistEmptyView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        VStack(spacing: 8) {
            MEGAAssetsImageProvider.image(named: .rectangleVideoStackOutline)
                .foregroundStyle(videoConfig.colorAssets.secondaryIconColor)
                .frame(width: 120, height: 120)
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.emptyState)
                .font(.body)
                .foregroundStyle(videoConfig.colorAssets.primaryTextColor)
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
}

#Preview {
    VideoPlaylistEmptyView(videoConfig: .preview)
}
