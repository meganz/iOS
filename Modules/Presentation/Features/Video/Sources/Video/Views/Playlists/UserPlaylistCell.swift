import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct UserPlaylistCell: View {
    @StateObject private var viewModel: VideoPlaylistCellViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistCellViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        UserPlaylistCellContent(
            videoConfig: videoConfig,
            previewEntity: viewModel.previewEntity,
            secondaryInformationViewType: viewModel.secondaryInformationViewType,
            isLoading: viewModel.isLoading,
            onTappedMoreOptions: { viewModel.onTappedMoreOptions() }
        )
        .task {
            await viewModel.onViewAppear()
        }
        .onTapGesture {
            router.openVideoPlaylistContent(for: viewModel.videoPlaylistEntity)
        }
    }
}

struct UserPlaylistCellContent: View {
    
    let videoConfig: VideoConfig
    let previewEntity: VideoPlaylistCellPreviewEntity
    let secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType
    let isLoading: Bool
    let onTappedMoreOptions: () -> Void
    
    var body: some View {
        HStack {
            content
        }
        .padding(0)
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            VideoListPlaceholderCell()
                .shimmering(active: isLoading)
        } else {
            ThumbnailLayerView(
                videoConfig: videoConfig,
                imageContainers: previewEntity.imageContainers,
                centerBackgroundImage: videoConfig.rowAssets.rectangleVideoStackPlaylistImage
            )
            .frame(width: 142, height: 80, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: TokenSpacing._3) {
                Text(previewEntity.title)
                    .font(.subheadline)
                    .foregroundStyle(videoConfig.colorAssets.primaryTextColor)
                
                secondaryInformationView()
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            Image(uiImage: videoConfig.rowAssets.moreImage)
                .foregroundStyle(videoConfig.colorAssets.secondaryIconColor)
                .onTapGesture { onTappedMoreOptions() }
        }
    }
    
    @ViewBuilder
    private func secondaryInformationView() -> some View {
        switch secondaryInformationViewType {
        case .emptyPlaylist:
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
        case .information:
            VideoPlaylistSecondaryInformationView(
                videoConfig: videoConfig,
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported
            )
        }
    }
}

#Preview {
    UserPlaylistCellContent(
        videoConfig: .preview,
        previewEntity: .preview(isExported: false),
        secondaryInformationViewType: .emptyPlaylist,
        isLoading: false,
        onTappedMoreOptions: {}
    )
    .frame(height: 80, alignment: .center)
}

#Preview {
    UserPlaylistCellContent(
        videoConfig: .preview,
        previewEntity: .preview(isExported: true),
        secondaryInformationViewType: .emptyPlaylist,
        isLoading: false,
        onTappedMoreOptions: {}
    )
    .preferredColorScheme(.dark)
    .frame(height: 80, alignment: .center)
}

#Preview {
    UserPlaylistCellContent(
        videoConfig: .preview,
        previewEntity: .preview(
            isExported: false,
            imageContainers: [
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail)
            ]
        ),
        secondaryInformationViewType: .information,
        isLoading: false,
        onTappedMoreOptions: {}
    )
    .frame(height: 80, alignment: .center)
}

private var sampleImage: Image {
    PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image
}
