import ContentLibraries
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import SwiftUI

struct AllVideosCollectionViewRepresenter: UIViewRepresentable {
    @ObservedObject var viewModel: AllVideosCollectionViewModel
    let videoConfig: VideoConfig
    let selection: VideoSelection
    let searchText: String?
    let router: any VideoRevampRouting
    let viewType: AllVideosViewControllerCollectionViewLayoutBuilder.ViewType
    let sectionTopInset: CGFloat
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    init(
        videos: [NodeEntity],
        searchText: String?,
        videoConfig: VideoConfig,
        selection: VideoSelection,
        router: some VideoRevampRouting,
        viewType: AllVideosViewControllerCollectionViewLayoutBuilder.ViewType,
        sectionTopInset: CGFloat = TokenSpacing._5,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.viewModel = AllVideosCollectionViewModel(
            videos: videos,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        self.searchText = searchText
        self.videoConfig = videoConfig
        self.selection = selection
        self.router = router
        self.viewType = viewType
        self.sectionTopInset = sectionTopInset
        self.featureFlagProvider = featureFlagProvider
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: AllVideosViewControllerCollectionViewLayoutBuilder(
                viewType: viewType,
                sectionTopInset: sectionTopInset
            ).build()
        )
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        collectionView.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        context.coordinator.configure(collectionView, searchText: searchText)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        // Update layout if sectionTopInset changed
        let newLayout = AllVideosViewControllerCollectionViewLayoutBuilder(
            viewType: viewType,
            sectionTopInset: sectionTopInset
        ).build()
        uiView.setCollectionViewLayout(newLayout, animated: true)

        context.coordinator.reloadData(with: viewModel.videos, searchText: searchText)
    }
    
    func makeCoordinator() -> AllVideosCollectionViewCoordinator {
        AllVideosCollectionViewCoordinator(self, featureFlagProvider: featureFlagProvider)
    }
}
