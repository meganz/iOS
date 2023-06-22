@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class EnforceCopyrightWarningViewModelTests: XCTestCase {
    
    func testDetermineViewState_noPublicLinksAndDeclinedBefore_shouldReturnDeclined() {
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = EnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                   shareUseCase: MockShareUseCase())
        XCTAssertEqual(sut.viewStatus, .unknown)
        sut.determineViewState()
        
        XCTAssertEqual(sut.viewStatus, .declined)
    }
    
    func testDetermineViewState_noPublicLinksAndAgreedBefore_shouldReturnAgreed() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.agreedCopywriteWarning: true])
        let sut = EnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                   shareUseCase: MockShareUseCase())
        sut.determineViewState()
        
        XCTAssertEqual(sut.viewStatus, .agreed)
    }
    
    func testDetermineViewState_publicLinksSharedAndDisagreedBefore_shouldSetToAgreedReturnAgreed() throws {
        let preferenceUseCase = MockPreferenceUseCase()
        let shareUseCase = MockShareUseCase(nodes: [NodeEntity(handle: 1)])
        let sut = EnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                   shareUseCase: shareUseCase)
        sut.determineViewState()
        
        let isAgreed = try XCTUnwrap(preferenceUseCase.dict[.agreedCopywriteWarning] as? Bool)
        XCTAssertTrue(isAgreed)
        XCTAssertEqual(sut.viewStatus, .agreed)
    }
    
    func testIsTermsAgreed_onAgreed_shouldSetPreferenceAndEmitAgreedViewStatus() throws {
        let preferenceUseCase = MockPreferenceUseCase()
        let shareUseCase = MockShareUseCase(nodes: [NodeEntity(handle: 1)])
        let sut = EnforceCopyrightWarningViewModel(preferenceUseCase: preferenceUseCase,
                                                   shareUseCase: shareUseCase)
        sut.isTermsAggreed = true
        let isAgreed = try XCTUnwrap(preferenceUseCase.dict[.agreedCopywriteWarning] as? Bool)
        XCTAssertTrue(isAgreed)
        XCTAssertEqual(sut.viewStatus, .agreed)
    }
    
    func testCopyrightMessage_shouldBeCombinedFromTwoParts() {
        let sut = EnforceCopyrightWarningViewModel(preferenceUseCase: MockPreferenceUseCase(),
                                                   shareUseCase: MockShareUseCase())
        
        let expectedCopyrightMessage = "\(Strings.Localizable.copyrightMessagePart1)\n\n\(Strings.Localizable.copyrightMessagePart2)"
        XCTAssertEqual(sut.copyrightMessage, expectedCopyrightMessage)
    }
}
