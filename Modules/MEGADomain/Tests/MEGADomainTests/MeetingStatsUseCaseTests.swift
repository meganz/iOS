import XCTest
import MEGADomain
import MEGADomainMock

class MeetingStatsUseCaseTests: XCTestCase {

    func testSendEvent_sendEndCallForAllStats() {
        let repo = MockStatsRepository.newRepo
        let usecase = MeetingStatsUseCase(repository: repo)
        
        usecase.sendEndCallForAllStats()
        
        XCTAssertTrue(repo.type == StatsEventEntity.clickMeetingEndCallForAll)
    }
}
