
import Combine
import Foundation
import MEGADomain

@MainActor
final class RecentlyWatchedVideosViewModel: ObservableObject {
    
    private let recentlyWatchedVideosUseCase: any RecentlyWatchedVideosUseCaseProtocol
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
        recentlyWatchedVideosUseCase: some RecentlyWatchedVideosUseCaseProtocol,
        recentlyWatchedVideosSorter: some RecentlyWatchedVideosSorterProtocol
    ) {
        self.recentlyWatchedVideosUseCase = recentlyWatchedVideosUseCase
        self.recentlyWatchedVideosSorter = recentlyWatchedVideosSorter
    }
    
    func loadRecentlyWatchedVideos() async {
        viewState = .loading
        do {
            let videos = try await recentlyWatchedVideosUseCase.loadVideos()
            recentlyWatchedSections = recentlyWatchedVideosSorter.sortVideosByDay(videos: videos)
            viewState = recentlyWatchedSections.isEmpty ? .empty : .loaded
        } catch {
            viewState = .error
        }
    }
}
