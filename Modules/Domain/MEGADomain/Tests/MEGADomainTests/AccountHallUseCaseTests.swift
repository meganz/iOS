import XCTest
import MEGADomain
import MEGADomainMock

final class AccountHallUseCaseTests: XCTestCase {
    
    func testContactRequestsCount_onViewAppear_shouldBeEqual() async  {
        let contactsRequestsExpectedCount = 1
        let sut = AccountHallUseCase(repository: MockAccountRepository(contactsRequestsCount: contactsRequestsExpectedCount))
        let contactsCount = await sut.incomingContactsRequestsCount()
        
        XCTAssertEqual(contactsCount, contactsRequestsExpectedCount)
    }
    
    func testUnseenUserAlertsCount_onViewAppear_shouldBeEqual() async  {
        let unSeenUserAlertsExpectedCount: UInt = 2
        let sut = AccountHallUseCase(repository: MockAccountRepository(unseenUserAlertsCount: unSeenUserAlertsExpectedCount))
        let unSeenUserAlertsCount = await sut.relevantUnseenUserAlertsCount()
        
        XCTAssertEqual(unSeenUserAlertsCount, unSeenUserAlertsExpectedCount)
    }
}
