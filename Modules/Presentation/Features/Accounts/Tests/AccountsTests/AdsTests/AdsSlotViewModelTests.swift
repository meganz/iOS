@testable import Accounts
import AccountsMock
import Combine
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

final class AdsSlotViewModelTests: XCTestCase {
    var subscriptions = Set<AnyCancellable>()
    
    private var adsCookieEnabled: Bool = false
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Subscription
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccessAndExternalAdsIsEnabled_shouldHideAds() async {
        await assertAccountDidPurchasedPlanNotif(isExternalAdsFlagEnabled: true)
    }
    
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccessAndExternalAdsIsDisabled_shouldDoNothing() async {
        await assertAccountDidPurchasedPlanNotif(isExternalAdsFlagEnabled: false)
    }
    
    private func assertAccountDidPurchasedPlanNotif(
        isExternalAdsFlagEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(isExternalAdsFlagEnabled: isExternalAdsFlagEnabled)
        await sut.setupAdsRemoteFlag()
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
        
        let displayAdsExp = expectation(description: "displayAds should should be \(expectedAdsFlag)")
        displayAdsExp.isInverted = !isExternalAdsFlagEnabled
        sut.$displayAds
            .dropFirst()
            .sink { _ in
                displayAdsExp.fulfill()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
        await fulfillment(of: [isExternalAdsEnabledExp, displayAdsExp], timeout: 1.0)

        XCTAssertEqual(sut.isExternalAdsEnabled, expectedAdsFlag, file: file, line: line)
        XCTAssertEqual(sut.displayAds, expectedAdsFlag, file: file, line: line)
    }
    
    // MARK: - Ads slot
    func testSetupAdsRemoteFlag_whenAccountIsNotFree_shouldDisableExternalAds() async {
        let billedAccountTypes = AccountTypeEntity.allCases.filter({ $0 != .free })
        for type in billedAccountTypes {
            let sut = makeSUT(accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: type)))
            await sut.setupAdsRemoteFlag()
            XCTAssertFalse(sut.isExternalAdsEnabled, "Account type \(type) should hide ads")
        }
    }
    
    func testSetupAdsRemoteFlag_whenAccountIsFreeWithSuccessAccountDetailsResult_shouldMatchExternalAdsValue() async {
        await assertSetupAdsRemoteFlag(isLoggedIn: true, accountDetailsResult: .success(AccountDetailsEntity.build(proLevel: .free)))
    }
                                       
    func testSetupAdsRemoteFlag_whenAccountIsFreeWithFailedAccountDetailsResult_shouldMatchExternalAdsValue() async {
        await assertSetupAdsRemoteFlag(isLoggedIn: true, accountDetailsResult: .failure(.generic))
    }
                                       
    func testSetupAdsRemoteFlag_whenNoLoggedInUser_shouldMatchExternalAdsValue() async {
        await assertSetupAdsRemoteFlag(isLoggedIn: false)
    }
    
    private func assertSetupAdsRemoteFlag(
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
        
        await sut.setupAdsRemoteFlag()
        
        XCTAssertEqual(sut.isExternalAdsEnabled, expectedExternalAdsValue, file: file, line: line)
    }

    func testUpdateAdsSlot_externalAdsDisabled_shouldHideAds() async {
        let sut = makeSUT(isExternalAdsFlagEnabled: false)
        
        await sut.setupAdsRemoteFlag()
        await sut.updateAdsSlot(randomAdsSlotConfig)
        
        XCTAssertNil(sut.adsSlotConfig)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testUpdateAdsSlot_externalAdsEnabledAndReceivedSameAdsSlot_withDifferentDisplayAdsValue_shouldHaveLatestDisplayAds() async {
        let randomAdSlot = randomAdsSlotConfig
        let expectedConfig = AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled)
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [
                AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: false, isAdsCookieEnabled: isAdsCookieEnabled),
                expectedConfig
            ],
            expectedLatestAdsSlotConfig: expectedConfig
        )
    }
    
    func testUpdateAdsSlot_externalAdsEnabledAndReceivedSameAdsSlot_withSameDisplayAdsValue_shouldHaveTheSameDisplayAdsValue() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot, randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot
        )
    }
    
    func testUpdateAdsSlot_externalAdsEnabledAndReceivedNewAdSlot_withSameDisplayAdsValues_shouldDisplayAds() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot
        )
    }
    
    private func assertUpdateAdsSlotShouldDisplayAds(
        adsSlots: [AdsSlotConfig],
        expectedLatestAdsSlotConfig: AdsSlotConfig,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: adsSlots)
        let sut = makeSUT(adsSlotChangeStream: stream, isExternalAdsFlagEnabled: true)
        
        // Set initial AdSlot
        await sut.updateAdsSlot(randomAdsSlotConfig)
        
        // Monitor Ads slot changes
        await sut.setupAdsRemoteFlag()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertEqual(sut.adsSlotConfig, expectedLatestAdsSlotConfig, file: file, line: line)
        XCTAssertEqual(sut.displayAds, expectedLatestAdsSlotConfig.displayAds, file: file, line: line)
    }
    
    func testInitializeGoogleAds_externalAdsEnabled_shouldInitialize() async {
        await assertInitializingGoogleAds(isExternalAdsFlagEnabled: true, expectedCallCount: 1)
    }
    
    func testInitializeGoogleAds_externalAdsDisabled_shouldNotInitialize() async {
        await assertInitializingGoogleAds(isExternalAdsFlagEnabled: false, expectedCallCount: 0)
    }
    
    private func assertInitializingGoogleAds(
        isExternalAdsFlagEnabled: Bool,
        expectedCallCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let adMobConsentManager = MockGoogleMobileAdsConsentManager()
        let sut = makeSUT(
            isExternalAdsFlagEnabled: isExternalAdsFlagEnabled,
            adMobConsentManager: adMobConsentManager
        )
        
        await sut.setupAdsRemoteFlag()
        await sut.initializeGoogleAds()
        
        XCTAssertEqual(adMobConsentManager.initializeGoogleMobileAdsSDKCalledCount, expectedCallCount, file: file, line: line)
    }
    
    func testAdMob_withTestEnvironment_shouldUseTestUnitID() {
        assertAdMob(
            forEnvs: AppConfigurationEntity.allCases.filter({ $0 != .production }),
            expectedAdMob: AdMob.test
        )
    }
    
    func testAdMob_withLiveEnvironment_shouldUseLiveUnitID() {
        assertAdMob(
            forEnvs: [.production],
            expectedAdMob: AdMob.live
        )
    }
    
    private func assertAdMob(forEnvs envs: [AppConfigurationEntity], expectedAdMob: AdMob) {
        let appEnvironmentUseCase = MockAppEnvironmentUseCase()
        let sut = makeSUT(appEnvironmentUseCase: appEnvironmentUseCase)
        
        envs.forEach { env in
            appEnvironmentUseCase.configuration = env
            XCTAssertEqual(sut.adMob, expectedAdMob, "\(env) environment should use the \(expectedAdMob) unit id")
        }
    }
    
    // MARK: Helper
    private func makeSUT(
        adsSlotChangeStream: any AdsSlotChangeStreamProtocol = MockAdsSlotChangeStream(),
        adsList: [String: String] = [:],
        isExternalAdsFlagEnabled: Bool = true,
        adMobConsentManager: GoogleMobileAdsConsentManagerProtocol = MockGoogleMobileAdsConsentManager(),
        appEnvironmentUseCase: some AppEnvironmentUseCaseProtocol = MockAppEnvironmentUseCase(),
        isNewAccount: Bool = false,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .success(AccountDetailsEntity.build(proLevel: .free)),
        isLoggedIn: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        let sut = AdsSlotViewModel(
            adsSlotChangeStream: adsSlotChangeStream,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(valueToReturn: isExternalAdsFlagEnabled),
            adMobConsentManager: adMobConsentManager,
            appEnvironmentUseCase: appEnvironmentUseCase,
            accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn, accountDetailsResult: accountDetailsResult)
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeMockAdsSlotChangeStream(adsSlotConfigs: [AdsSlotConfig?]) -> MockAdsSlotChangeStream {
        let adsSlotStream = AsyncStream<AdsSlotConfig?> { continuation in
            adsSlotConfigs.forEach { config in
                continuation.yield(config)
            }
            continuation.finish()
        }
        return MockAdsSlotChangeStream(adsSlotStream: adsSlotStream)
    }

    private var randomAdsSlotConfig: AdsSlotConfig {
        let adsSlot: AdsSlotEntity = [.files, .home, .photos, .sharedLink].randomElement() ?? .files
        return AdsSlotConfig(adsSlot: adsSlot, displayAds: Bool.random(), isAdsCookieEnabled: isAdsCookieEnabled)
    }
    
    private func isAdsCookieEnabled() async -> Bool {
        adsCookieEnabled
    }
}
