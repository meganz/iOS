
import Combine
import Foundation
import MEGADomain

@MainActor
final class RecentlyWatchedVideosViewModel: ObservableObject {
    
    private let recentlyOpenedNodesUseCase: any RecentlyOpenedNodesUseCaseProtocol
    private let recentlyWatchedVideosSorter: any RecentlyWatchedVideosSorterProtocol
    
    @Published private(set) var viewState: ViewState = .partial
    @Published private(set) var recentlyWatchedSections: [RecentlyWatchedVideoSection] = []
    
    enum ViewState: Equatable {
        case partial
        case loading
        case loaded
        case empty
        case error
    }
    
    init(
        recentlyOpenedNodesUseCase: some RecentlyOpenedNodesUseCaseProtocol,
        recentlyWatchedVideosSorter: some RecentlyWatchedVideosSorterProtocol
    ) {
        self.recentlyOpenedNodesUseCase = recentlyOpenedNodesUseCase
        self.recentlyWatchedVideosSorter = recentlyWatchedVideosSorter
    }
    
    func loadRecentlyWatchedVideos() async {
        viewState = .loading
        do {
            let videos = try await recentlyOpenedNodesUseCase.loadNodes().filter(\.node.name.fileExtensionGroup.isVideo)
            recentlyWatchedSections = recentlyWatchedVideosSorter.sortVideosByDay(videos: videos)
            viewState = recentlyWatchedSections.isEmpty ? .empty : .loaded
        } catch {
            viewState = .error
        }
    }
}
