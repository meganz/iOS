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
            isSelectionEnabled: viewModel.isSelectionEnabled,
            isSelected: viewModel.isSelected,
            isDisabled: viewModel.isDisabled,
            onTappedMoreOptions: viewModel.onTappedMoreOptions,
            onCheckMarkTapped: viewModel.onItemSelected
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
    let isSelectionEnabled: Bool
    let isSelected: Bool
    let isDisabled: Bool
    let onTappedMoreOptions: () -> Void
    let onCheckMarkTapped: () -> Void
    
    var body: some View {
        HStack(spacing: TokenSpacing._3) {
            checkMarkView
            content
        }
        .padding(0)
        .background(TokenColors.Background.page.swiftUI)
    }
    
    @ViewBuilder
    private var checkMarkView: some View {
        if isSelectionEnabled {
            Button(action: onCheckMarkTapped) {
                CheckMarkView(
                    markedSelected: isSelected,
                    foregroundColor: isSelected ? TokenColors.Support.success.swiftUI : TokenColors.Border.strong.swiftUI
                )
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            VideoListPlaceholderCell()
                .shimmering(active: isLoading)
        } else {
            HStack(spacing: TokenSpacing._3) {
                ThumbnailLayerView(
                    thumbnail: previewEntity.thumbnail,
                    videoPlaylistType: previewEntity.type
                )
                .frame(width: 142, height: 80, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .opacity(isDisabled ? 0.5 : 1)
                
                VStack(alignment: .leading, spacing: TokenSpacing._3) {
                    Text(previewEntity.title)
                        .font(.subheadline)
                        .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.primary.swiftUI)
                    
                    secondaryInformationView()
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .gesture(isSelectionEnabled ? tap : nil)
            
            MEGAAssetsImageProvider.image(named: .moreList)
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .opacity(isSelectionEnabled ? 0 : 1)
                .onTapGesture { onTappedMoreOptions() }
        }
    }
    
    private var tap: some Gesture { TapGesture().onEnded(onCheckMarkTapped) }
    
    @ViewBuilder
    private func secondaryInformationView() -> some View {
        switch secondaryInformationViewType {
        case .emptyPlaylist:
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(isDisabled ? TokenColors.Text.disabled.swiftUI : TokenColors.Text.primary.swiftUI)
        case .information:
            VideoPlaylistSecondaryInformationView(
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported,
                layoutIgnoringOrientation: false,
                isDisabled: isDisabled
            )
        }
    }
}

#Preview {
    UserPlaylistCellContent(
        previewEntity: .preview(isExported: false),
        secondaryInformationViewType: .emptyPlaylist,
        isLoading: false,
        isSelectionEnabled: false,
        isSelected: false,
        isDisabled: false,
        onTappedMoreOptions: {},
        onCheckMarkTapped: {}
    )
    .frame(height: 80, alignment: .center)
}

#Preview {
    UserPlaylistCellContent(
        previewEntity: .preview(isExported: true),
        secondaryInformationViewType: .emptyPlaylist,
        isLoading: false,
        isSelectionEnabled: false,
        isSelected: false,
        isDisabled: false,
        onTappedMoreOptions: {},
        onCheckMarkTapped: {}
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
        isSelectionEnabled: false,
        isSelected: false,
        isDisabled: false,
        onTappedMoreOptions: {},
        onCheckMarkTapped: {}
    )
    .frame(height: 80, alignment: .center)
}

private var sampleImage: Image {
    PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image
}
