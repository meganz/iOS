import MEGADomain
import MEGAPresentation
import SwiftUI
import UIKit

extension VideoRevampFactory {
    
    @MainActor
    public static func makeRecentlyWatchedVideosView(
        recentlyOpenedNodesUseCase: some RecentlyOpenedNodesUseCaseProtocol,
        videoConfig: VideoConfig,
        sharedUIState: RecentlyWatchedVideosSharedUIState,
        router: some VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) -> UIViewController {
        let viewModel = RecentlyWatchedVideosViewModel(
            recentlyOpenedNodesUseCase: recentlyOpenedNodesUseCase,
            recentlyWatchedVideosSorter: RecentlyWatchedVideosSorter(),
            sharedUIState: sharedUIState
        )
        let view = RecentlyWatchedVideosView(
            viewModel: viewModel,
            videoConfig: videoConfig,
            router: router,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
        return viewController
    }
}
