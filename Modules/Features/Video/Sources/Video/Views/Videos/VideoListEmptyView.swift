import MEGAL10n
import SwiftUI

struct VideoListEmptyView: View {
    
    let videoConfig: VideoConfig
    let image: UIImage
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
            Text(text)
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
}

#Preview {
    VideoListEmptyView(
        videoConfig: .preview,
        image: VideoConfig.preview.videoListAssets.noResultVideoImage,
        text: Strings.Localizable.Videos.Tab.All.Content.emptyState
    )
}
