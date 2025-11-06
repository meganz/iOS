import ContentLibraries
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct RecentlyWatchedVideosView: View {
    
    @StateObject private var viewModel: RecentlyWatchedVideosViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(
        viewModel: @autoclosure @escaping () -> RecentlyWatchedVideosViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    var body: some View {
        RecentlyWatchedVideosContent(
            viewState: viewModel.viewState,
            sections: viewModel.recentlyWatchedSections,
            videoConfig: videoConfig,
            router: router,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        .task {
            await viewModel.loadRecentlyWatchedVideos()
        }
        .confirmationDialog(Strings.Localizable.Videos.RecentlyWatched.Deletion.Alert.title, isPresented: $viewModel.shouldShowDeleteAlert) {
            Button(Strings.Localizable.Videos.RecentlyWatched.Deletion.Alert.Option.clearRecentlyWatched, role: .destructive) {
                viewModel.clearRecentlyWatchedVideos()
            }
            Button(Strings.Localizable.cancel, role: .cancel) { }
        } message: {
            Text(Strings.Localizable.Videos.RecentlyWatched.Deletion.Alert.title)
        }     
    }
}

struct RecentlyWatchedVideosContent: View {
    
    let viewState: RecentlyWatchedVideosViewModel.ViewState
    let sections: [RecentlyWatchedVideoSection]
    let videoConfig: VideoConfig
    
    let router: any VideoRevampRouting
    let thumbnailLoader: any ThumbnailLoaderProtocol
    let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    let nodeUseCase: any NodeUseCaseProtocol
    let featureFlagProvider: any FeatureFlagProviderProtocol
    
    var body: some View {
        switch viewState {
        case .partial:
            EmptyView()
        case .loading:
            EmptyView() // Todo: CC-8411
        case .loaded:
            listView()
        case .empty:
            videoEmptyView()
        case .error:
            EmptyView()
        }
    }
    
    private func listView() -> some View {
        RecentlyWatchedVideosCollectionViewRepresenter(
            viewModel: RecentlyWatchedVideosCollectionViewModel(
                sections: sections,
                thumbnailLoader: thumbnailLoader,
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                nodeUseCase: nodeUseCase,
                featureFlagProvier: featureFlagProvider
            ),
            videoConfig: videoConfig,
            router: router
        )
    }
    
    private func videoEmptyView() -> some View {
        VideoListEmptyView(
            videoConfig: .preview,
            image: videoConfig.recentsEmptyStateImage,
            text: Strings.Localizable.Videos.RecentlyWatched.emptyState
        )
    }
}

// MARK: - Preview

#Preview {
    recentlyWatchedVideosContent(
        viewState: .empty,
        sections: []
    )
}

#Preview {
    recentlyWatchedVideosContent(
        viewState: .loaded,
        sections: sections()
    )
}

// MARK: - Helpers

@MainActor
private func recentlyWatchedVideosContent(
    viewState: RecentlyWatchedVideosViewModel.ViewState,
    sections: [RecentlyWatchedVideoSection]
) -> RecentlyWatchedVideosContent {
    RecentlyWatchedVideosContent(
        viewState: viewState,
        sections: sections,
        videoConfig: .preview,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: true)
        
    )
}

private func sections() -> [RecentlyWatchedVideoSection] {
    [
        RecentlyWatchedVideoSection(
            title: "Today",
            videos: [
                RecentlyOpenedNodeEntity(
                    node: .preview,
                    lastOpenedDate: Date(), // Today
                    mediaDestination: mediaDestination()
                )
            ]
        ),
        RecentlyWatchedVideoSection(
            title: "Yesterday",
            videos: [
                RecentlyOpenedNodeEntity(
                    node: anyVideo(handle: 3),
                    lastOpenedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), // Yesterday
                    mediaDestination: mediaDestination()
                ),
                RecentlyOpenedNodeEntity(
                    node: anyVideo(handle: 4),
                    lastOpenedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                    mediaDestination: mediaDestination()
                )
            ]
        ),
        RecentlyWatchedVideoSection(
            title: "Sat, 23 Sept 2023",
            videos: [
                RecentlyOpenedNodeEntity(
                    node: anyVideo(handle: 5),
                    lastOpenedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), // 2 days ago
                    mediaDestination: mediaDestination()
                ),
                RecentlyOpenedNodeEntity(
                    node: anyVideo(handle: 6),
                    lastOpenedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()), // 3 days ago
                    mediaDestination: mediaDestination()
                )
            ]
        )
    ]
}

private func anyVideo(handle: Int) -> NodeEntity {
    .preview
}

private func mediaDestination() -> MediaDestinationEntity {
    MediaDestinationEntity(fingerprint: "any", destination: 0, timescale: 0)
}
