@testable import Chat
import MEGADomain
import MEGADomainMock
import XCTest

final class RaiseHandBadgeStoreTests: XCTestCase {
    class Harness {
        let sut: RaiseHandBadgeStore
        let userAttributeUseCase: MockUserAttributeUseCase

        init(
            raiseHandNewFeatureBadge: RaiseHandNewFeatureBadgeEntity? = nil
        ) {
            userAttributeUseCase = MockUserAttributeUseCase(raiseHandNewFeatureBadge: raiseHandNewFeatureBadge)
            
            sut = .init(
                userAttributeUseCase: userAttributeUseCase
            )
        }
        
        static func presentedTimes(count: Int) -> Harness {
            Harness(raiseHandNewFeatureBadge: RaiseHandNewFeatureBadgeEntity(presentedCount: count))
        }
        
        func raiseHandBadgePreferenceSaved(presentedCount: Int) -> Bool {
            userAttributeUseCase.userAttributeContainer[.appsPreferences]?[RaiseHandNewFeatureBadgeKeyEntity.key] == "\(presentedCount)"
        }
    }
    
    func testIncrementRaiseHandBadgePresentedCount_countMustBeIncrementedByOne() async {
        let presentedCount = 3
        let harness = Harness.presentedTimes(count: presentedCount)
        await harness.sut.incrementRaiseHandBadgePresented()
        XCTAssertTrue(harness.raiseHandBadgePreferenceSaved(presentedCount: presentedCount + 1))
    }
    
    func testSaveRaiseHandBadgeAsPresented_countMustPassTheMaxLimit() async {
        let presentedCount = 1
        let harness = Harness.presentedTimes(count: presentedCount)
        await harness.sut.saveRaiseHandBadgeAsPresented()
        XCTAssertTrue(harness.raiseHandBadgePreferenceSaved(presentedCount: RaiseHandBadgeStore.Constants.raiseHandBadgeMaxPresentedCount))
    }
}
