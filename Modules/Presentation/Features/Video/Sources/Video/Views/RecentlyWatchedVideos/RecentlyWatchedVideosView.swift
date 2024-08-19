import MEGADesignToken
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
            text: "No recent activity" // CC-7877
        )
    }
}

#Preview {
    RecentlyWatchedVideosView(videoConfig: .preview)
}
