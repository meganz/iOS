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
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccess_shouldHideAds() async {
        let sut = makeSUT()
        await sut.setupSubscriptions()
        
        let exp = expectation(description: "displayAds should emit the correct value")
        sut.$displayAds
            .dropFirst()
            .sink { displayAds in
                XCTAssertFalse(displayAds)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    // MARK: - Ads slot
    func testUpdateAdsSlot_externalAdsDisabled_shouldHideAds() async {
        let sut = makeSUT(isExternalAdsFlagEnabled: false)
        
        await sut.setupAdsRemoteFlag()
        await sut.updateAdsSlot(randomAdsSlotConfig)
        
        XCTAssertNil(sut.adsSlotConfig)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testUpdateAdsSlot_externalAdsEnabled_receivedSameAdsSlot_withDifferentDisplayAdsValue_shouldHaveLatestDisplayAds() async {
        let randomAdSlot = randomAdsSlotConfig
        let expectedConfig = AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled)
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [
                AdsSlotConfig(adsSlot: randomAdSlot.adsSlot, displayAds: false, isAdsCookieEnabled: isAdsCookieEnabled),
                expectedConfig
            ],
            expectedLatestAdsSlotConfig: expectedConfig,
            shouldRefreshAds: false
        )
    }
    
    func testUpdateAdsSlot_externalAdsEnabled_receivedSameAdsSlot_withSameDisplayAdsValue_shouldHaveTheSameDisplayAdsValue() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot, randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot,
            shouldRefreshAds: false
        )
    }
    
    func testUpdateAdsSlot_externalAdsEnabled_receivedNewAdSlot_shouldDisplayAdsAndRefresh() async {
        let randomAdSlot = randomAdsSlotConfig
        
        await assertUpdateAdsSlotShouldDisplayAds(
            adsSlots: [randomAdSlot],
            expectedLatestAdsSlotConfig: randomAdSlot,
            shouldRefreshAds: true
        )
    }
    
    private func assertUpdateAdsSlotShouldDisplayAds(
        adsSlots: [AdsSlotConfig],
        expectedLatestAdsSlotConfig: AdsSlotConfig,
        shouldRefreshAds: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: adsSlots)
        let sut = makeSUT(adsSlotChangeStream: stream, isExternalAdsFlagEnabled: true)
        
        // Set initial AdSlot
        await sut.updateAdsSlot(randomAdsSlotConfig)
        
        // Refresh ads if needed
        let exp = expectation(description: "Should refresh ads: \(shouldRefreshAds)")
        exp.isInverted = !shouldRefreshAds
        exp.expectedFulfillmentCount = adsSlots.count
        sut.refreshAdsPublisher
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        await sut.setupAdsRemoteFlag()
        await sut.monitorAdsSlotChanges()
        await fulfillment(of: [exp], timeout: 0.5)
        
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        let sut = AdsSlotViewModel(
            adsSlotChangeStream: adsSlotChangeStream,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(valueToReturn: isExternalAdsFlagEnabled),
            adMobConsentManager: adMobConsentManager,
            appEnvironmentUseCase: appEnvironmentUseCase
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
