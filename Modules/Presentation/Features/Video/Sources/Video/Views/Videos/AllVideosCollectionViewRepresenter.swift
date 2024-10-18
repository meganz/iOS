import MEGADomain
import MEGAPresentation
import SwiftUI

struct AllVideosCollectionViewRepresenter: UIViewRepresentable {
    @ObservedObject var viewModel: AllVideosCollectionViewModel
    let videoConfig: VideoConfig
    let selection: VideoSelection
    let router: any VideoRevampRouting
    let viewType: ViewType
    
    enum ViewType {
        case allVideos
        case playlists
        case playlistContent(type: VideoPlaylistEntityType)
    }
    
    init(
        videos: [NodeEntity],
        videoConfig: VideoConfig,
        selection: VideoSelection,
        router: some VideoRevampRouting,
        viewType: ViewType,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.viewModel = AllVideosCollectionViewModel(
            videos: videos,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        self.videoConfig = videoConfig
        self.selection = selection
        self.router = router
        self.viewType = viewType
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder(viewType: viewType).build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        context.coordinator.configure(collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: viewModel.videos)
    }
    
    func makeCoordinator() -> AllVideosCollectionViewCoordinator {
        AllVideosCollectionViewCoordinator(self)
    }
}
