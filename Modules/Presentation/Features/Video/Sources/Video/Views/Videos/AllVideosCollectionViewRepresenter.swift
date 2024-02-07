import MEGADomain
import SwiftUI

struct AllVideosCollectionViewRepresenter: UIViewRepresentable {
    @ObservedObject var viewModel: AllVideosCollectionViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videos: [NodeEntity],
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        self.viewModel = AllVideosCollectionViewModel(thumbnailUseCase: thumbnailUseCase, videos: videos)
        self.videoConfig = videoConfig
        self.router = router
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder().build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: viewModel.videos)
    }
    
    func makeCoordinator() -> AllVideosCollectionViewCoordinator {
        AllVideosCollectionViewCoordinator(self)
    }
}
