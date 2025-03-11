@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGASwift
import MEGATest
import XCTest

final class AdsSlotViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Subscription
    @MainActor
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccessAndExternalAdsIsEnabled_shouldHideAds() async {
        await assertAccountDidPurchasedPlanNotif(isExternalAdsFlagEnabled: true)
    }
    
    @MainActor
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccessAndExternalAdsIsDisabled_shouldDoNothing() async {
        await assertAccountDidPurchasedPlanNotif(isExternalAdsFlagEnabled: false)
    }
    
    @MainActor private func assertAccountDidPurchasedPlanNotif(
        isExternalAdsFlagEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(isExternalAdsFlagEnabled: isExternalAdsFlagEnabled)
        await sut.determineAdsAvailability()
        sut.setupSubscriptions()
        
        let expectedAdsFlag = isExternalAdsFlagEnabled ? false : isExternalAdsFlagEnabled
        
        let isExternalAdsEnabledExp = expectation(description: "isExternalAdsEnabled should be \(expectedAdsFlag)")
        isExternalAdsEnabledExp.isInverted = !isExternalAdsFlagEnabled
        sut.$isExternalAdsEnabled
            .dropFirst()
            .sink { _ in
                isExternalAdsEnabledExp.fulfill()
            }
            .store(in: &subscriptions)
        
        let displayAdsExp = expectation(description: "displayAds should be \(expectedAdsFlag)")
        displayAdsExp.isInverted = !isExternalAdsFlagEnabled
        sut.$displayAds
            .dropFirst()
            .sink { _ in
                displayAdsExp.fulfill()
            }
            .store(in: &subscriptions)
        
        let showAdsFreeViewExp = expectation(description: "showAdsFreeView should be \(expectedAdsFlag)")
        showAdsFreeViewExp.isInverted = !isExternalAdsFlagEnabled
        sut.$showAdsFreeView
            .dropFirst()
            .sink { _ in
                showAdsFreeViewExp.fulfill()
            }
            .store(in: &subscriptions)
        
        notificationCenter.post(name: .accountDidPurchasedPlan, object: nil)
        await fulfillment(of: [isExternalAdsEnabledExp, displayAdsExp, showAdsFreeViewExp], timeout: 1.0)

        XCTAssertEqual(sut.isExternalAdsEnabled, expectedAdsFlag, file: file, line: line)
        XCTAssertEqual(sut.displayAds, expectedAdsFlag, file: file, line: line)
        XCTAssertEqual(sut.showAdsFreeView, expectedAdsFlag, file: file, line: line)
    }
    
    @MainActor func testStartAdsNotification_whenIsExternalAdsEnabledIsNil_shouldDetermineAndSetAdsAvailability() {
        assertStartAdsNotification(setCurrentAdsValue: false)
    }
    
    @MainActor func testStartAdsNotification_whenIsExternalAdsEnabledIsAlreadySet_shouldDoNothing() {
        assertStartAdsNotification(setCurrentAdsValue: true)
    }
    
    @MainActor private func assertStartAdsNotification(setCurrentAdsValue: Bool) {
        let expectedAdsValue = Bool.random()
        let sut = makeSUT(isExternalAdsFlagEnabled: expectedAdsValue)
        if setCurrentAdsValue {
            sut.isExternalAdsEnabled = expectedAdsValue
        }
        sut.setupSubscriptions()
        
        let adsExp = expectation(description: "isExternalAdsEnabled should be determined only when it is nil")
        adsExp.isInverted = setCurrentAdsValue
        sut.$isExternalAdsEnabled
            .dropFirst()
            .sink { _ in
                adsExp.fulfill()
            }
            .store(in: &subscriptions)
        
        notificationCenter.post(name: .startAds, object: nil)
        
        wait(for: [adsExp], timeout: 1.0)
        XCTAssertEqual(sut.isExternalAdsEnabled, expectedAdsValue)
    }
    
    // MARK: - Submit receipt
    @MainActor func testSubmitReceiptResultPublisher_successResult_shouldKeepAdsDisplayStatus() async {
        await assertSubmitReceiptResultPublisher(
            result: .success,
            currentAdsSlotConfig: randomAdsSlotConfig,
            currentIsExternalAdsFlagEnabled: false,
            shouldCheckAdsDisplay: false,
            expectedIsExternalAdsEnabled: false,
            expectedDisplayAds: false
        )
    }
    
    @MainActor func testSubmitReceiptResultPublisher_failedResult_shouldRecheckAdsDisplayStatus() async {
        // When a user has successfully purchased a plan from Upgrade page but received failed result on submitting the receipt.
        // In this case, ads should show again if isExternalAdsFlagEnabled's actual value is true.
        let adsSlot = randomAdsSlotConfig
        await assertSubmitReceiptResultPublisher(
            result: .failure(.init(errorCode: -11, errorMessage: nil)),
            currentAdsSlotConfig: adsSlot,
            currentIsExternalAdsFlagEnabled: false, // When user has purchased a plan, isExternalAdsEnabled is automatically set to false.
            shouldCheckAdsDisplay: true,
            expectedIsExternalAdsEnabled: true, // Actual value of isExternalAdsEnabled of the account.
            expectedDisplayAds: adsSlot.displayAds
        )
    }

    @MainActor private func assertSubmitReceiptResultPublisher(
        result: Result<Void, AccountPlanErrorEntity>,
        currentAdsSlotConfig: AdsSlotConfig,
        currentIsExternalAdsFlagEnabled: Bool,
        shouldCheckAdsDisplay: Bool,
        expectedIsExternalAdsEnabled: Bool,
        expectedDisplayAds: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let submitReceiptResultPublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
        let sut = makeSUT(
            purchaseUseCase: MockAccountPlanPurchaseUseCase(
                submitReceiptResultPublisher: submitReceiptResultPublisher
            ),
            isExternalAdsFlagEnabled: expectedIsExternalAdsEnabled
        )
        await sut.determineAdsAvailability()
        sut.updateAdsSlot(currentAdsSlotConfig)
        sut.isExternalAdsEnabled = currentIsExternalAdsFlagEnabled
        sut.setupSubscriptions()
        
        let isExternalAdsEnabledExp = expectation(description: "isExternalAdsEnabled should be \(expectedIsExternalAdsEnabled)")
        isExternalAdsEnabledExp.isInverted = !shouldCheckAdsDisplay
        sut.$isExternalAdsEnabled
            .dropFirst()
            .sink { _ in
                isExternalAdsEnabledExp.fulfill()
            }
            .store(in: &subscriptions)
        
        let displayAdsExp = expectation(description: "displayAds should be \(expectedDisplayAds)")
        displayAdsExp.isInverted = !shouldCheckAdsDisplay
        sut.$displayAds
            .dropFirst()
            .sink { _ in
                displayAdsExp.fulfill()
            }
            .store(in: &subscriptions)
        
        submitReceiptResultPublisher.send(result)
        
        await fulfillment(of: [isExternalAdsEnabledExp, displayAdsExp], timeout: 1.0)
        
        XCTAssertEqual(sut.isExternalAdsEnabled, expectedIsExternalAdsEnabled, file: file, line: line)
        XCTAssertEqual(sut.displayAds, expectedDisplayAds, file: file, line: line)
    }
    
    // MARK: - Ads slot
    @MainActor func testDetermineAdsAvailability_whenAccountIsNotFree_shouldDisableExternalAds() async throws {
        let billedAccountTypes = AccountTypeEntity.allCases.filter({ $0 != .free })
        for type in billedAccountTypes {
            let sut = makeSUT(accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: type)))
            await sut.determineAdsAvailability()
            let isExternalAdsEnabled = try XCTUnwrap(sut.isExternalAdsEnabled)
            XCTAssertFalse(isExternalAdsEnabled, "Account type \(type) should hide ads")
        }
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAccountIsFreeWithSuccessAccountDetailsResult_shouldMatchExternalAdsValue() async {
        await assertDetermineAdsAvailability(isLoggedIn: true, accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: .free)))
    }
              
    @MainActor
    func testDetermineAdsAvailability_whenAccountIsFreeWithFailedAccountDetailsResult_shouldMatchExternalAdsValue() async {
        await assertDetermineAdsAvailability(isLoggedIn: true, accountDetailsResult: .failure(.generic))
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenNoLoggedInUser_shouldMatchExternalAdsValue() async {
        await assertDetermineAdsAvailability(isLoggedIn: false)
    }
    
    @MainActor private func assertDetermineAdsAvailability(
        isLoggedIn: Bool = true,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .success(AccountDetailsEntity.build(proLevel: .free)),
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let expectedExternalAdsValue = Bool.random()
        let sut = makeSUT(
            isExternalAdsFlagEnabled: expectedExternalAdsValue,
            accountDetailsResult: accountDetailsResult,
            isLoggedIn: isLoggedIn
        )
        
        await sut.determineAdsAvailability()
        
        XCTAssertEqual(sut.isExternalAdsEnabled, expectedExternalAdsValue, file: file, line: line)
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAdsIsEnabledAndHasPublicFileLinkThatShouldHaveAds_shouldEnableExternalAds() async {
        await assertDetermineAdsAvailabilityWithPublicLinks(queryAdsValue: 0, isFolderLink: false, expectedExternalAdsValue: true)
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAdsIsEnabledAndHasPublicFileLinkThatShouldNotHaveAds_shouldDisableExternalAds() async {
        await assertDetermineAdsAvailabilityWithPublicLinks(queryAdsValue: 1, isFolderLink: false, expectedExternalAdsValue: false)
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAdsIsEnabledAndHasPublicFolderLinkThatShouldHaveAds_shouldEnableExternalAds() async {
        await assertDetermineAdsAvailabilityWithPublicLinks(queryAdsValue: 0, isFolderLink: true, expectedExternalAdsValue: true)
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAdsIsEnabledAndHasPublicFolderLinkThatShouldNotHaveAds_shouldDisableExternalAds() async {
        await assertDetermineAdsAvailabilityWithPublicLinks(queryAdsValue: 1, isFolderLink: true, expectedExternalAdsValue: false)
    }
    
    @MainActor
    func testDetermineAdsAvailability_whenAdsIsDisabledAndHasPublicLinkThatShouldHaveAds_shouldStillDisableExternalAds() async {
        await assertDetermineAdsAvailabilityWithPublicLinks(isAdsEnabled: false, queryAdsValue: 0, isFolderLink: Bool.random(), expectedExternalAdsValue: false)
    }
    
    @MainActor
    func assertDetermineAdsAvailabilityWithPublicLinks(
        isAdsEnabled: Bool = true,
        queryAdsValue: Int,
        isFolderLink: Bool,
        expectedExternalAdsValue: Bool
    ) async {
        // queryAdsValue
        // 0 - show ads
        // 1 - do not show ads
        let sut = makeSUT(
            adsUseCase: MockAdsUseCase(queryAdsValue: queryAdsValue),
            nodeUseCase: MockNodeUseCase(folderLinkInfo: FolderLinkInfoEntity(), nodeForFileLink: NodeEntity()),
            isExternalAdsFlagEnabled: isAdsEnabled,
            accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: .free)),
            isLoggedIn: true,
            publicNodeLink: "https://mega.nz/link/1dICRLJS#snJiad_4WfCKEK7bgPri3A",
            isFolderLink: isFolderLink
        )
        
        await sut.determineAdsAvailability()
        
        XCTAssertEqual(sut.isExternalAdsEnabled, expectedExternalAdsValue)
    }

    @MainActor func testUpdateAdsSlot_externalAdsDisabled_shouldHideAds() async {
        let sut = makeSUT(isExternalAdsFlagEnabled: false)
        
        await sut.determineAdsAvailability()
        sut.updateAdsSlot(randomAdsSlotConfig)
        
        XCTAssertNil(sut.adsSlotConfig)
        XCTAssertFalse(sut.displayAds)
    }
    
    @MainActor func testUpdateAdsSlot_externalAdsIsNil_shouldSetAdsSlotConfig() async {
        let sut = makeSUT()
        
        XCTAssertNil(sut.isExternalAdsEnabled)
        
        let expectedAdsSlotConfig = randomAdsSlotConfig
        sut.updateAdsSlot(expectedAdsSlotConfig)
        
        XCTAssertEqual(sut.adsSlotConfig, expectedAdsSlotConfig)
        XCTAssertEqual(sut.displayAds, expectedAdsSlotConfig.displayAds)
    }
    
    @MainActor func testUpdateAdsSlot_externalAdsEnabledAndReceivedSameAdsSlot_withDifferentDisplayAdsValue_shouldHaveLatestDisplayAds() async {
        let randomAdSlot = randomAdsSlotConfig
        let expectedConfig = AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: true)
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [
                AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: false),
                expectedConfig
            ],
            expectedLatestAdsSlotConfig: expectedConfig
        )
    }
    
    @MainActor
    func testUpdateAdsSlot_externalAdsEnabledAndReceivedSameAdsSlot_withSameDisplayAdsValue_shouldHaveTheSameDisplayAdsValue() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot, randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot
        )
    }
    
    @MainActor
    func testUpdateAdsSlot_externalAdsEnabledAndReceivedNewAdSlot_withSameDisplayAdsValues_shouldDisplayAds() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot
        )
    }
    
    @MainActor private func assertUpdateAdsSlotShouldDisplayAds(
        adsSlots: [AdsSlotConfig],
        expectedLatestAdsSlotConfig: AdsSlotConfig,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let adsSlotUpdates = MockAdsSlotUpdatesProvider(
            adsSlotUpdates: makeAdsSlotUpdatesStream(adsSlotConfigs: adsSlots).eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(adsSlotUpdatesProvider: adsSlotUpdates, isExternalAdsFlagEnabled: true)
        
        // Set initial AdSlot
        sut.updateAdsSlot(randomAdsSlotConfig)
        
        // Monitor Ads slot changes
        await sut.determineAdsAvailability()
        sut.startMonitoringAdsSlotUpdates()
        await sut.monitorAdsSlotUpdatesTask?.value
        
        XCTAssertEqual(sut.adsSlotConfig, expectedLatestAdsSlotConfig, file: file, line: line)
        XCTAssertEqual(sut.displayAds, expectedLatestAdsSlotConfig.displayAds, file: file, line: line)
    }
    
    @MainActor func testStopMonitoringAdsSlotUpdates_shouldCancelTask() async {
        let sut = makeSUT(isExternalAdsFlagEnabled: true)
        sut.startMonitoringAdsSlotUpdates()
        await sut.monitorAdsSlotUpdatesTask?.value
        
        sut.stopMonitoringAdsSlotUpdates()
        XCTAssertTrue(sut.monitorAdsSlotUpdatesTask?.isCancelled ?? false)
    }
    
    @MainActor func testAdMob_withTestEnvironment_shouldUseTestUnitID() {
        assertAdMob(
            forEnvs: AppConfigurationEntity.allCases.filter({ $0 != .production }),
            expectedAdMob: AdMob.test
        )
    }
    
    @MainActor func testAdMob_withLiveEnvironment_shouldUseLiveUnitID() {
        assertAdMob(
            forEnvs: [.production],
            expectedAdMob: AdMob.live
        )
    }
    
    @MainActor private func assertAdMob(forEnvs envs: [AppConfigurationEntity], expectedAdMob: AdMob) {
        let appEnvironmentUseCase = MockAppEnvironmentUseCase()
        let sut = makeSUT(appEnvironmentUseCase: appEnvironmentUseCase)
        
        envs.forEach { env in
            appEnvironmentUseCase.configuration = env
            XCTAssertEqual(sut.adMob, expectedAdMob, "\(env) environment should use the \(expectedAdMob) unit id")
        }
    }
    
    // MARK: - Close button
    @MainActor func testBannerViewDidReceiveAdSuccess_whenNoLoggedInUser_shouldSetShowCloseButtonToFalse() {
        assertShowCloseButton(isLoggedIn: false)
    }
    
    @MainActor func testBannerViewDidReceiveAdSuccess_whenUserIsLoggedIn_shouldSetShowCloseButtonToTrue() {
        assertShowCloseButton(isLoggedIn: true)
    }
    
    @MainActor private func assertShowCloseButton(isLoggedIn: Bool) {
        var loggerCalled: Bool = false
        let sut = makeSUT(isLoggedIn: isLoggedIn, logger: { _ in loggerCalled = true })
        
        XCTAssertFalse(sut.showCloseButton)
        
        sut.bannerViewDidReceiveAdsUpdate(result: .success)
        
        XCTAssertEqual(sut.showCloseButton, isLoggedIn)
        XCTAssertTrue(loggerCalled)
    }
    
    @MainActor func testBannerViewDidReceiveAdWithError_shouldCallLogger() {
        enum TestError: Error {
            case anyError
        }
        
        var loggerCalled: Bool = false
        let sut = makeSUT(logger: { _ in loggerCalled = true })
        
        sut.bannerViewDidReceiveAdsUpdate(result: .failure(TestError.anyError))
        
        XCTAssertTrue(loggerCalled)
    }
    
    @MainActor func testDidTapCloseAdsButton_shouldSetShowAdsFreeViewToTrue() {
        let sut = makeSUT()
        
        sut.didTapCloseAdsButton()
        
        XCTAssertTrue(sut.showAdsFreeView)
    }
    
    @MainActor func testDidTapCloseAdsButton_shouldSaveLastTappedDate() {
        let currentTestDate = Date()
        let sut = makeSUT(expectedCloseAdsButtonTappedDate: currentTestDate)
        
        sut.didTapCloseAdsButton()
        
        XCTAssertEqual(sut.lastCloseAdsDate, currentTestDate, "Expected close ads button last tapped date should be the current date")
    }
    
    @MainActor func testDidTapCloseAdsButton_shouldTrackButtonTapEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(tracker: mockTracker)
        
        sut.didTapCloseAdsButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [AdsBannerCloseAdsButtonPressedEvent()]
        )
    }
    
    // MARK: Helper
    @MainActor private func makeSUT(
        adsSlotUpdatesProvider: some AdsSlotUpdatesProviderProtocol = MockAdsSlotUpdatesProvider(),
        adsUseCase: some AdsUseCaseProtocol = MockAdsUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol = MockAccountPlanPurchaseUseCase(),
        adsList: [String: String] = [:],
        isExternalAdsFlagEnabled: Bool = true,
        adMobConsentManager: GoogleMobileAdsConsentManagerProtocol = MockGoogleMobileAdsConsentManager(),
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = MockAppEnvironmentUseCase(),
        isNewAccount: Bool = false,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .success(AccountDetailsEntity.build(proLevel: .free)),
        expectedCloseAdsButtonTappedDate: Date = Date(),
        tracker: some AnalyticsTracking = MockTracker(),
        isLoggedIn: Bool = true,
        publicNodeLink: String? = nil,
        isFolderLink: Bool = false,
        logger: ((String) -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        let sut = AdsSlotViewModel(
            adsSlotUpdatesProvider: adsSlotUpdatesProvider,
            adsUseCase: adsUseCase,
            nodeUseCase: nodeUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsFlagEnabled]),
            adMobConsentManager: adMobConsentManager,
            appEnvironmentUseCase: appEnvironmentUseCase,
            accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn, accountDetailsResult: accountDetailsResult),
            purchaseUseCase: purchaseUseCase,
            preferenceUseCase: MockPreferenceUseCase(),
            tracker: tracker,
            adsFreeViewProPlanAction: {},
            currentDate: { expectedCloseAdsButtonTappedDate },
            notificationCenter: notificationCenter,
            publicNodeLink: publicNodeLink,
            isFolderLink: isFolderLink,
            logger: logger
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeAdsSlotUpdatesStream(adsSlotConfigs: [AdsSlotConfig?]) -> AnyAsyncSequence<AdsSlotConfig?> {
        AsyncStream { continuation in
            adsSlotConfigs.forEach {
                continuation.yield($0)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }

    private var randomAdsSlotConfig: AdsSlotConfig {
        let adsSlot: AdsSlotEntity = [.files, .home, .photos, .sharedLink].randomElement() ?? .files
        return AdsSlotConfig(adsSlot: adsSlot, displayAds: Bool.random())
    }
}
