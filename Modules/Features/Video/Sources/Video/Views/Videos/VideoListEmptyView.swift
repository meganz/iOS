import MEGAL10n
import SwiftUI

struct VideoListEmptyView: View {
    
    let videoConfig: VideoConfig
    let image: UIImage
    let text: String
    let backgroundColor: Color

    init(
        videoConfig: VideoConfig,
        image: UIImage,
        text: String,
        backgroundColor: Color? = nil
    ) {
        self.videoConfig = videoConfig
        self.image = image
        self.text = text
        self.backgroundColor = backgroundColor ?? videoConfig.colorAssets.pageBackgroundColor
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
            Text(text)
        }
        .background(backgroundColor)
    }
}

#Preview {
    VideoListEmptyView(
        videoConfig: .preview,
        image: VideoConfig.preview.videoListAssets.noResultVideoImage,
        text: Strings.Localizable.Videos.Tab.All.Content.emptyState
    )
}
