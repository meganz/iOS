import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import SwiftUI

struct RecentlyWatchedVideosCollectionViewRepresenter: UIViewRepresentable {
    @StateObject var viewModel: RecentlyWatchedVideosCollectionViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> RecentlyWatchedVideosCollectionViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder(viewType: .recentlyWatchedVideos).build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: viewModel.sections)
    }
    
    public func makeCoordinator() -> RecentlyWatchedVideosCollectionViewCoordinator {
        RecentlyWatchedVideosCollectionViewCoordinator(self)
    }
}
