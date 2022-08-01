@testable import MEGA
import MEGADomain

final class MockMediaDiscoveryStatsUseCase: MediaDiscoveryStatsUseCaseProtocol {
    var hasPageVisitedCalled = false
    var hasPageStayCalled = false
    
    func sendPageVisitedStats() {
        hasPageVisitedCalled = true
    }
    
    func sendPageStayStats(with duration: Int) {
        hasPageStayCalled = true
    }
}
