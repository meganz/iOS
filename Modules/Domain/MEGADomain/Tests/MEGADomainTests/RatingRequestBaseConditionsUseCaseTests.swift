import MEGADomain
import MEGADomainMock
import XCTest

class RatingRequestBaseConditionsUseCaseTests: XCTestCase {
    func testBaseConditions_met() {
        let sut =
            RatingRequestBaseConditionsUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.lastRequestedVersionForRating: "0.1"]),
                                               accountRepo: MockAccountRepository(nodesCount: 20),
                                               currentAppVersion: "1")
        
        XCTAssertTrue(sut.hasMetBaseConditions())
    }

    func testBaseConditions_notMet_noEnoughNodes() {
        let sut =
            RatingRequestBaseConditionsUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.lastRequestedVersionForRating: "0.1"]),
                                               accountRepo: MockAccountRepository(nodesCount: 19),
                                               currentAppVersion: "1")
        
        XCTAssertFalse(sut.hasMetBaseConditions())
    }
    
    func testBaseConditions_notMet_versionRequested() {
        let sut =
            RatingRequestBaseConditionsUseCase(preferenceUserCase: MockPreferenceUseCase(dict: [.lastRequestedVersionForRating: "5.17.1"]),
                                               accountRepo: MockAccountRepository(nodesCount: 21),
                                               currentAppVersion: "5.17.1")
        
        XCTAssertFalse(sut.hasMetBaseConditions())
    }
    
    func testSaveRequestedVersion() {
        let preference = MockPreferenceUseCase()
        XCTAssertTrue(preference.dict.isEmpty)
        let sut = RatingRequestBaseConditionsUseCase(preferenceUserCase: preference,
                                                     accountRepo: MockAccountRepository(nodesCount: 21),
                                                     currentAppVersion: "5.17.1")
        sut.saveLastRequestedAppVersion("5.17.1")
        XCTAssertEqual(preference.dict.count, 1)
        XCTAssertEqual("5.17.1", preference[.lastRequestedVersionForRating])
    }
}
