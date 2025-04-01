@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class UpgradeEncouragementViewModelTests: XCTestCase {
    var sut: UpgradeEncouragementViewModel!
    var router: MockUpgradeAccountRouter!
    var showTimeTracker: MockUpgradeEncouragementShowTimeTracker!
    var randomNumberGenerator: MockRandomNumberGenerator!
    
    override func setUp() {
        super.setUp()
        router = .init()
        showTimeTracker = .init()
        randomNumberGenerator = .init()
        randomNumberGenerator.generateRecorder.stubbedReturns = 0
    }
    
    override func tearDown() {
        super.tearDown()
        sut = nil
        router = nil
        showTimeTracker = nil
        randomNumberGenerator = nil
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_whenAlreadyPresented_shouldNotTriggerRouter() {
        // given
        showTimeTracker.alreadyPresented = true
        
        sut = makeSUT()
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertFalse(randomNumberGenerator.generateRecorder.called)
        XCTAssertFalse(router.presentUpgradeTVCRecorder.called)
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_whenIsProAccount_shouldNotTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(currentAccountDetails: MockMEGAAccountDetails.proAccounDetailsEntity)
        sut = makeSUT(accountUseCase: accountUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertFalse(randomNumberGenerator.generateRecorder.called)
        XCTAssertFalse(router.presentUpgradeTVCRecorder.called)
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_whenIsFreeAccount_createdLessThanThreeDays_shouldNotTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(accountCreationDate: Date().daysAgo(1), currentAccountDetails: MockMEGAAccountDetails.freeAccountDetailsEntity)
        sut = makeSUT(accountUseCase: accountUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertFalse(randomNumberGenerator.generateRecorder.called)
        XCTAssertFalse(router.presentUpgradeTVCRecorder.called)
    }
    
    // MARK: - From here, test functions are implicitly have inputs with free account and created more than 3 days
    @MainActor
    func testEncourageUpgradeIfNeeded_randomNumberIsTwenty_shouldNotTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(accountCreationDate: Date().daysAgo(6), currentAccountDetails: MockMEGAAccountDetails.freeAccountDetailsEntity)

        let preferenceUseCase = MockPreferenceUseCase(dict: [.lastEncourageUpgradeDate: Date().daysAgo(10)!])
        randomNumberGenerator.generateRecorder.stubbedReturns = 20
        
        sut = makeSUT(accountUseCase: accountUseCase, preferenceUseCase: preferenceUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertTrue(randomNumberGenerator.generateRecorder.called)
        XCTAssertFalse(router.presentUpgradeTVCRecorder.called)
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_randomNumberIsOne_lastEncourageUgradeLessThanOneWeek_shouldNotTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(accountCreationDate: Date().daysAgo(5), currentAccountDetails: MockMEGAAccountDetails.freeAccountDetailsEntity)

        let preferenceUseCase = MockPreferenceUseCase(dict: [.lastEncourageUpgradeDate: Date().daysAgo(4)!])
        randomNumberGenerator.generateRecorder.stubbedReturns = 1
        
        sut = makeSUT(accountUseCase: accountUseCase, preferenceUseCase: preferenceUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertTrue(randomNumberGenerator.generateRecorder.called)
        XCTAssertFalse(router.presentUpgradeTVCRecorder.called)
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_randomNumberIsOne_lastEncourageUgradeDateIsNil_shouldTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(accountCreationDate: Date().daysAgo(5), currentAccountDetails: MockMEGAAccountDetails.freeAccountDetailsEntity)

        let preferenceUseCase = MockPreferenceUseCase(dict: [:])
        randomNumberGenerator.generateRecorder.stubbedReturns = 1
        
        sut = makeSUT(accountUseCase: accountUseCase, preferenceUseCase: preferenceUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertTrue(randomNumberGenerator.generateRecorder.called)
        XCTAssertNotNil(preferenceUseCase[.lastEncourageUpgradeDate])
        XCTAssertTrue(router.presentUpgradeTVCRecorder.called)
    }
    
    @MainActor
    func testEncourageUpgradeIfNeeded_randomNumberIsOne_lastEncourageUgradeMoreThanOneWeek_shouldTriggerRouter() {
        // given
        let accountUseCase = MockAccountUseCase(accountCreationDate: Date().daysAgo(6), currentAccountDetails: MockMEGAAccountDetails.freeAccountDetailsEntity)
        
        randomNumberGenerator.generateRecorder.stubbedReturns = 1

        let preferenceUseCase = MockPreferenceUseCase(dict: [.lastEncourageUpgradeDate: Date().daysAgo(10)!])
        
        sut = makeSUT(accountUseCase: accountUseCase, preferenceUseCase: preferenceUseCase)
        
        // when
        sut.encourageUpgradeIfNeeded()
        
        // then
        XCTAssertEqual(router.presentUpgradeTVCRecorder.callCount, 1)
        XCTAssertTrue(showTimeTracker.alreadyPresented)
        
        // and when
        sut.encourageUpgradeIfNeeded()
        
        // and then
        
        XCTAssertEqual(router.presentUpgradeTVCRecorder.callCount, 1)
    }
    
    @MainActor
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase()
    ) -> UpgradeEncouragementViewModel {
        .init(
            showTimeTracker: showTimeTracker,
            accountUseCase: accountUseCase,
            router: router,
            preferenceUseCase: preferenceUseCase,
            randomNumberGenerator: randomNumberGenerator)
    }
}

private extension MockMEGAAccountDetails {
    static let freeAccountDetailsEntity = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
    static let proAccounDetailsEntity = MockMEGAAccountDetails(type: .proI).toAccountDetailsEntity()
}
