import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentlyWatchedVideosView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        videoEmptyView()
    }
    
    private func videoEmptyView() -> some View {
        VideoListEmptyView(
            videoConfig: .preview,
            image: videoConfig.recentsEmptyStateImage,
            text: Strings.Localizable.Videos.RecentlyWatched.emptyState
        )
    }
}

#Preview {
    RecentlyWatchedVideosView(videoConfig: .preview)
}
