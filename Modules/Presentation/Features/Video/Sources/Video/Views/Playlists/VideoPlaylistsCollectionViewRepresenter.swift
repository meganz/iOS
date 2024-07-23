import MEGADomain
import MEGAPresentation
import SwiftUI

struct VideoPlaylistsCollectionViewRepresenter: UIViewRepresentable {
    let thumbnailLoader: any ThumbnailLoaderProtocol
    @StateObject var viewModel: VideoPlaylistsViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    let didSelectMoreOptionForItem: (VideoPlaylistEntity) -> Void
    
    init(
        thumbnailLoader: some ThumbnailLoaderProtocol,
        viewModel: @autoclosure @escaping () -> VideoPlaylistsViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting,
        didSelectMoreOptionForItem: @escaping (VideoPlaylistEntity) -> Void
    ) {
        self.thumbnailLoader = thumbnailLoader
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
        self.didSelectMoreOptionForItem = didSelectMoreOptionForItem
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder(viewType: .playlists).build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: viewModel.videoPlaylists)
    }
    
    func makeCoordinator() -> VideoPlaylistsCollectionViewCoordinator {
        VideoPlaylistsCollectionViewCoordinator(self)
    }
}
