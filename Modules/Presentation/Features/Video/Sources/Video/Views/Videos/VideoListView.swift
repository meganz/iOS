import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

struct VideoListView: View {
    @ObservedObject var viewModel: VideoListViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    
    var body: some View {
        VStack(spacing: 0) {
            switch viewModel.uiState {
            case .empty:
                VideoListEmptyView(videoConfig: videoConfig)
            case .loaded:
                listView()
            default:
                EmptyView()
            }
        }
        .task {
            await viewModel.loadVideos()
        }
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            thumbnailUseCase: viewModel.thumbnailUseCase,
            videos: viewModel.videos,
            videoConfig: videoConfig,
            router: router
        )
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
        VideoListView(
            viewModel: VideoListViewModel(
                fileSearchUseCase: Preview_FilesSearchUseCase(),
                thumbnailUseCase: Preview_ThumbnailUseCase()
            ),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter()
        )
    }
}
