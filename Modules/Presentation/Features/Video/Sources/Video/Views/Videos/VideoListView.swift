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
            if viewModel.videos.isEmpty {
                VideoListEmptyView(videoConfig: videoConfig)
            } else if viewModel.videos.isNotEmpty {
                listView()
            } else {
                EmptyView()
            }
        }
        .task {
            await viewModel.onViewAppeared()
            await viewModel.monitorSortOrderChanged()
        }
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            thumbnailUseCase: viewModel.thumbnailUseCase,
            videos: viewModel.videos,
            videoConfig: videoConfig,
            router: router
        )
        .background(videoConfig.colorAssets.pageBackgroundColor)
        .onDisappear {
            viewModel.onViewDissapeared()
        }
    }
}

struct VideoListEmptyView: View {
    
    let videoConfig: VideoConfig
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: videoConfig.videoListAssets.noResultVideoImage)
            Text(Strings.Localizable.Videos.Tab.All.Content.emptyState)
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView(
            viewModel: VideoListViewModel(
                fileSearchUseCase: Preview_FilesSearchUseCase(),
                thumbnailUseCase: Preview_ThumbnailUseCase(),
                syncModel: VideoRevampSyncModel()
            ),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter()
        )
    }
}
