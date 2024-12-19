import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct UserPlaylistCell: View {
    @StateObject private var viewModel: VideoPlaylistCellViewModel
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistCellViewModel,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.router = router
    }
    
    var body: some View {
        UserPlaylistCellContent(
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
    
    let previewEntity: VideoPlaylistCellPreviewEntity
    let secondaryInformationViewType: VideoPlaylistCellViewModel.SecondaryInformationViewType
    let isLoading: Bool
    let onTappedMoreOptions: () -> Void
    
    var body: some View {
        HStack {
            content
        }
        .padding(0)
        .background(TokenColors.Background.page.swiftUI)
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            VideoListPlaceholderCell()
                .shimmering(active: isLoading)
        } else {
            ThumbnailLayerView(
                thumbnail: previewEntity.thumbnail,
                videoPlaylistType: previewEntity.type
            )
            .frame(width: 142, height: 80, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: TokenSpacing._3) {
                Text(previewEntity.title)
                    .font(.subheadline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                secondaryInformationView()
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            MEGAAssetsImageProvider.image(named: .moreList)
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .onTapGesture { onTappedMoreOptions() }
        }
    }
    
    @ViewBuilder
    private func secondaryInformationView() -> some View {
        switch secondaryInformationViewType {
        case .emptyPlaylist:
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        case .information:
            VideoPlaylistSecondaryInformationView(
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported,
                layoutIgnoringOrientation: false
            )
        }
    }
}

#Preview {
    UserPlaylistCellContent(
        previewEntity: .preview(isExported: false),
        secondaryInformationViewType: .emptyPlaylist,
        isLoading: false,
        onTappedMoreOptions: {}
    )
    .frame(height: 80, alignment: .center)
}

#Preview {
    UserPlaylistCellContent(
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
