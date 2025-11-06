import MEGADomain
import MEGASwift
@testable import Video

final class MockRecentlyWatchedVideosSorter: RecentlyWatchedVideosSorterProtocol, @unchecked Sendable {
    
    enum Invocation: Equatable {
        case sortVideosByDay
    }
    
    @Atomic var invocations: [Invocation] = []
    
    private let sortVideosByDayResult: [RecentlyWatchedVideoSection]
    
    init(sortVideosByDayResult: [RecentlyWatchedVideoSection] = []) {
        self.sortVideosByDayResult = sortVideosByDayResult
    }
    
    func sortVideosByDay(
        videos: [RecentlyOpenedNodeEntity],
        configuration: RecentlyWatchedVideosSectionDateConfiguration = RecentlyWatchedVideosSectionDateConfiguration()
    ) -> [RecentlyWatchedVideoSection] {
        $invocations.mutate { $0.append(.sortVideosByDay) }
        return sortVideosByDayResult
    }
}
