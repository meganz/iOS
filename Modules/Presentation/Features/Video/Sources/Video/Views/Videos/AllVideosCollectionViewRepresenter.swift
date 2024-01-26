import MEGADomain
import SwiftUI

struct AllVideosCollectionViewRepresenter: UIViewRepresentable {
    let thumbnailUseCase: any ThumbnailUseCaseProtocol
    let videos: [NodeEntity]
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    
    init(
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        videos: [NodeEntity],
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.videos = videos
        self.videoConfig = videoConfig
        self.router = router
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder().build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(with: videos)
    }
    
    func makeCoordinator() -> AllVideosCollectionViewCoordinator {
        AllVideosCollectionViewCoordinator(self)
    }
}
