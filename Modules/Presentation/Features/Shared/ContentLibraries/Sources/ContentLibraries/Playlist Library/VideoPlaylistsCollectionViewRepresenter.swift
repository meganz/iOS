import MEGADesignToken
import MEGADomain
import MEGAPresentation
import SwiftUI

public struct VideoPlaylistsCollectionViewRepresenter<ViewModel: VideoPlaylistsContentViewModelProtocol>: UIViewRepresentable {
    @StateObject var viewModel: ViewModel
    let router: any VideoRevampRouting
    let didSelectMoreOptionForItem: (VideoPlaylistEntity) -> Void
    
    public init(
        viewModel: @autoclosure @escaping () -> ViewModel,
        router: some VideoRevampRouting,
        didSelectMoreOptionForItem: @escaping (VideoPlaylistEntity) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.router = router
        self.didSelectMoreOptionForItem = didSelectMoreOptionForItem
    }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder(viewType: .playlists).build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = TokenColors.Background.page
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: viewModel.videoPlaylists)
    }
    
    public func makeCoordinator() -> VideoPlaylistsCollectionViewCoordinator<ViewModel> {
        VideoPlaylistsCollectionViewCoordinator(self)
    }
}
