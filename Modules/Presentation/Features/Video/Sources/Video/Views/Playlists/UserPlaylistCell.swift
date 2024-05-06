import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct UserPlaylistCell: View {
    @StateObject private var viewModel: VideoPlaylistCellViewModel
    private let videoConfig: VideoConfig
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistCellViewModel,
        videoConfig: VideoConfig
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
    }
    
    var body: some View {
        UserPlaylistCellContent(
            videoConfig: videoConfig,
            previewEntity: viewModel.previewEntity
        )
        .task {
            await viewModel.onViewAppeared()
        }
    }
}

struct UserPlaylistCellContent: View {
    
    let videoConfig: VideoConfig
    let previewEntity: VideoPlaylistCellPreviewEntity
    
    var body: some View {
        HStack {
            VideoPlaylistThumbnailView(videoConfig: videoConfig, imageContainers: previewEntity.imageContainers)
                .frame(width: 142, height: 80, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: TokenSpacing._3) {
                Text(previewEntity.title)
                    .font(.subheadline)
                    .foregroundStyle(videoConfig.colorAssets.primaryTextColor)
                
                VideoPlaylistSecondaryInformationView(
                    videoConfig: videoConfig,
                    videosCount: previewEntity.count,
                    totalDuration: previewEntity.duration,
                    isPublicLink: previewEntity.isExported
                )
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            Image(uiImage: videoConfig.rowAssets.moreImage)
                .foregroundStyle(videoConfig.colorAssets.secondaryIconColor)
        }
        .padding(0)
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
}

#Preview {
    UserPlaylistCellContent(
        videoConfig: .preview,
        previewEntity: .preview(isExported: false)
    )
    .frame(height: 80, alignment: .center)
}

#Preview {
    UserPlaylistCellContent(
        videoConfig: .preview,
        previewEntity: .preview(isExported: true)
    )
    .preferredColorScheme(.dark)
    .frame(height: 80, alignment: .center)
}
