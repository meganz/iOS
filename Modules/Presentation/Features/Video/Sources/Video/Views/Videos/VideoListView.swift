import MEGAAssets
import MEGAL10n
import SwiftUI

struct VideoListView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        VideoListEmptyView(videoConfig: videoConfig)
    }
}

struct VideoListEmptyView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: videoConfig.videoListAssets.noResultVideoImage)
            Text(Strings.Localizable.Videos.Tab.All.Content.emptyState)
        }
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView(videoConfig: .preview)
    }
}
