import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel: VideoListViewModel
    
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoListViewModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
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
        .task {
            await viewModel.listenSearchTextChange()
        }
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            thumbnailUseCase: viewModel.thumbnailUseCase,
            videos: viewModel.videos,
            videoConfig: videoConfig,
            selection: viewModel.selection,
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
                syncModel: VideoRevampSyncModel(),
                selection: VideoSelection()
            ),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter()
        )
    }
}
