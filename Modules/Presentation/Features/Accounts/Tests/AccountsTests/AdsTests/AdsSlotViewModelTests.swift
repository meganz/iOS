@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
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
        try await assertDetermineAdsAvailabilityForAccountTypeList(
            billedAccountTypes: AccountTypeEntity.allCases.filter({ $0 != .free }),
            hasValidProOrUnexpiredBusinessAccount: true
        )
    }
    
    @MainActor func testDetermineAdsAvailability_whenAccountIsExpiredBusinessAndExpiredProFlexi_shouldEnableExternalAds() async throws {
        try await assertDetermineAdsAvailabilityForAccountTypeList(
            billedAccountTypes: [.business, .proFlexi],
            hasValidProOrUnexpiredBusinessAccount: false
        )
    }
    
    @MainActor private func assertDetermineAdsAvailabilityForAccountTypeList(
        billedAccountTypes: [AccountTypeEntity],
        hasValidProOrUnexpiredBusinessAccount: Bool
    ) async throws {
        for type in billedAccountTypes {
            let mockAccountUseCase = MockAccountUseCase(
                isLoggedIn: true,
                accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: type)),
                hasValidProOrUnexpiredBusinessAccount: hasValidProOrUnexpiredBusinessAccount)
            let sut = makeSUT(accountUseCase: mockAccountUseCase)
            await sut.determineAdsAvailability()
            let isExternalAdsEnabled = try XCTUnwrap(sut.isExternalAdsEnabled)
            let expectedIsExternalAdsEnabled = !hasValidProOrUnexpiredBusinessAccount
            XCTAssertEqual(
                isExternalAdsEnabled,
                expectedIsExternalAdsEnabled,
                "Account type \(type) should \(expectedIsExternalAdsEnabled ? "show" : "hide") ads"
            )
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
            accountUseCase: MockAccountUseCase(
                isLoggedIn: isLoggedIn,
                accountDetailsResult: accountDetailsResult
            ),
            isExternalAdsFlagEnabled: expectedExternalAdsValue
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
            accountUseCase: MockAccountUseCase(
                isLoggedIn: true,
                accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: .free))
            ),
            isExternalAdsFlagEnabled: isAdsEnabled,
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
        let expectedConfig = AdsSlotConfig(displayAds: true)
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [
                AdsSlotConfig(displayAds: false),
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
    
    @MainActor func testStartMonitoringOnAccountUpdates_whenReceivedUpgradeUpdate_shouldCallLoadUserAndHideAds() async {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let accountUseCase = MockAccountUseCase(
            isLoggedIn: true,
            hasValidProOrUnexpiredBusinessAccount: true,
            onAccountUpdates: stream.eraseToAnyAsyncSequence()
        )
        let sut = makeSUT(
            accountUseCase: accountUseCase,
            isExternalAdsFlagEnabled: false
        )
        sut.isExternalAdsEnabled = true

        sut.startMonitoringOnAccountUpdates()
        continuation.yield(Void())
        continuation.finish()
        await sut.monitoringOnAccountUpdatesTask?.value
        
        XCTAssertEqual(sut.isExternalAdsEnabled, false)
        XCTAssertEqual(sut.showAdsFreeView, false)
        XCTAssertEqual(accountUseCase.loadUserData_calledCount, 1)
        XCTAssertEqual(sut.displayAds, false)
        XCTAssertEqual(sut.adsSlotConfig, nil)
    }

    @MainActor func testStopMonitoringOnAccountUpdates_shouldCancelTask() async {
        let sut = makeSUT(isExternalAdsFlagEnabled: true)
        sut.startMonitoringOnAccountUpdates()
        await sut.monitoringOnAccountUpdatesTask?.value
        
        sut.stopMonitoringOnAccountUpdates()
        XCTAssertTrue(sut.monitoringOnAccountUpdatesTask?.isCancelled ?? false)
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
        let sut = makeSUT(accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn))
        
        XCTAssertFalse(sut.showCloseButton)
        
        sut.bannerViewDidReceiveAdsUpdate(result: .success)
        
        XCTAssertEqual(sut.showCloseButton, isLoggedIn)
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
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        adsList: [String: String] = [:],
        isExternalAdsFlagEnabled: Bool = true,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = MockGoogleMobileAdsConsentManager(),
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = MockAppEnvironmentUseCase(),
        isNewAccount: Bool = false,
        expectedCloseAdsButtonTappedDate: Date = Date(),
        tracker: some AnalyticsTracking = MockTracker(),
        publicNodeLink: String? = nil,
        isFolderLink: Bool = false,
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
            accountUseCase: accountUseCase,
            purchaseUseCase: purchaseUseCase,
            preferenceUseCase: MockPreferenceUseCase(),
            tracker: tracker,
            adsFreeViewProPlanAction: {},
            currentDate: { expectedCloseAdsButtonTappedDate },
            notificationCenter: notificationCenter,
            publicNodeLink: publicNodeLink,
            isFolderLink: isFolderLink
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
        return AdsSlotConfig(displayAds: Bool.random())
    }
}
