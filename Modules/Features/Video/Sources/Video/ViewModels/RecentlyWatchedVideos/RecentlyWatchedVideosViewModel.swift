import Combine
import Foundation
import MEGADomain

@MainActor
final class RecentlyWatchedVideosViewModel: ObservableObject {
    
    private let recentlyOpenedNodesUseCase: any RecentlyOpenedNodesUseCaseProtocol
    private let recentlyWatchedVideosSorter: any RecentlyWatchedVideosSorterProtocol
    private let sharedUIState: RecentlyWatchedVideosSharedUIState
    
    @Published private(set) var viewState: ViewState = .partial
    @Published private(set) var recentlyWatchedSections: [RecentlyWatchedVideoSection] = []
    @Published var shouldShowDeleteAlert = false
    
    enum ViewState: Equatable {
        case partial
        case loading
        case loaded
        case empty
        case error
    }
    
    init(
        recentlyOpenedNodesUseCase: some RecentlyOpenedNodesUseCaseProtocol,
        recentlyWatchedVideosSorter: some RecentlyWatchedVideosSorterProtocol,
        sharedUIState: RecentlyWatchedVideosSharedUIState
    ) {
        self.recentlyOpenedNodesUseCase = recentlyOpenedNodesUseCase
        self.recentlyWatchedVideosSorter = recentlyWatchedVideosSorter
        self.sharedUIState = sharedUIState
        
        sharedUIState.$shouldShowDeleteAlert
            .receive(on: DispatchQueue.main)
            .assign(to: &$shouldShowDeleteAlert)
    }
    
    func loadRecentlyWatchedVideos() async {
        viewState = .loading
        do {
            let videos = try await recentlyOpenedNodesUseCase.loadNodes().filter(\.node.name.fileExtensionGroup.isVideo)
            recentlyWatchedSections = recentlyWatchedVideosSorter.sortVideosByDay(videos: videos)
            viewState = recentlyWatchedSections.isEmpty ? .empty : .loaded
            sharedUIState.isRubbishBinBarButtonItemEnabled = recentlyWatchedSections.isNotEmpty
        } catch {
            viewState = .error
        }
    }
    
    func clearRecentlyWatchedVideos() {
        // Todo: CC-7818
    }
}
