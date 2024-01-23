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
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Subscription
    func testAccountDidPurchasedPlanNotif_purchasedAccountSuccess_shouldHideAds() async {
        let sut = makeSUT()
        sut.setupSubscriptions()
        
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
        
        await sut.hideAdsForUpgradedAccountTask?.value
        XCTAssertFalse(sut.displayAds)
    }
    
    // MARK: - Ads slot
    func testLoadAdsForAdsSlot_featureFlagEnabled_abTestAdsEnabled_shouldHaveNewUrlAndDisplayAds() async {
        let expectedAdsSlotConfig = randomAdsSlotConfig
        let expectedAdsUrl = adsList[expectedAdsSlotConfig.adsSlot.rawValue]
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [expectedAdsSlotConfig])
        let sut = makeSUT(adsSlotChangeStream: stream,
                          adsList: adsList,
                          featureFlags: [.inAppAds: true],
                          abTestProvider: MockABTestProvider(list: [.ads: .variantA]))
        
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertNotNil(sut.adsUrl)
        XCTAssertEqual(sut.adsUrl?.absoluteString, expectedAdsUrl)
        XCTAssertEqual(sut.displayAds, expectedAdsSlotConfig.displayAds)
    }
    
    func testLoadAdsForAdsSlot_featureFlagEnabled_abTestAdsDisabled_shouldHaveNilUrlAndDontDisplayAds() async {
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [randomAdsSlotConfig])
        let sut = makeSUT(adsSlotChangeStream: stream,
                          adsList: adsList,
                          featureFlags: [.inAppAds: true],
                          abTestProvider: MockABTestProvider(list: [.ads: .baseline]))
        
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testLoadAdsForAdsSlot_noAds_shouldHaveNilUrlAndDontDisplayAds() async {
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [nil])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testLoadAdsForAdsSlotList_shouldMatchDisplayAdsValue() async {
        var adsSlotConfigs = [AdsSlotConfig(adsSlot: .files, displayAds: true),  // show ads on cloud drive
                              AdsSlotConfig(adsSlot: .home, displayAds: true),   // show ads on home
                              AdsSlotConfig(adsSlot: .home, displayAds: false),  // hide ads on home
                              AdsSlotConfig(adsSlot: .photos, displayAds: true), // show ads on photos
                              AdsSlotConfig(adsSlot: .files, displayAds: false)] // hide ads on cloud drive
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: adsSlotConfigs)
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        
        sut.$displayAds
            .dropFirst()
            .sink { displayAds in
                let adsSlotConfig = adsSlotConfigs.removeFirst()
                XCTAssertEqual(displayAds, adsSlotConfig.displayAds)
            }
            .store(in: &subscriptions)

        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
    }
    
    func testLoadAdsForAdsSlotList_shouldMatchAdsUrl() async {
        var adsSlotConfigs = [AdsSlotConfig(adsSlot: .files, displayAds: true),  // show ads on cloud drive
                              AdsSlotConfig(adsSlot: .photos, displayAds: true), // show ads on photos
                              AdsSlotConfig(adsSlot: .home, displayAds: true)]   // show ads on home
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: adsSlotConfigs)
        let ads = adsList
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: ads)
        
        sut.$adsUrl
            .dropFirst()
            .sink { url in
                let adsSlotConfig = adsSlotConfigs.removeFirst()
                XCTAssertEqual(url?.absoluteString, ads[adsSlotConfig.adsSlot.rawValue])
            }
            .store(in: &subscriptions)
        
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
    }
    
    func testUpdateAdsSlot_sameAdsSlotConfig_adsUrlIsNil_shouldNotDisplayAds() async {
        let adsSlotConfigs = [AdsSlotConfig(adsSlot: .home, displayAds: true),
                                     AdsSlotConfig(adsSlot: .home, displayAds: false),
                                     AdsSlotConfig(adsSlot: .home, displayAds: true)]
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: adsSlotConfigs)
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: [:])
        sut.adsUrl = nil

        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertFalse(sut.displayAds)
        XCTAssertNil(sut.adsUrl)
    }
    
    func testUpdateAdsSlot_sameAdsSlotConfig_shouldNotChangeURLandDisplayAdsValue() async {
        let expectedAdsSlotConfig = randomAdsSlotConfig
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [expectedAdsSlotConfig])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        let currentAdsUrl = sut.adsUrl
        let currentDisplayAds = sut.displayAds
        await sut.updateAdsSlot(expectedAdsSlotConfig)
        
        XCTAssertEqual(currentAdsUrl, sut.adsUrl)
        XCTAssertEqual(currentDisplayAds, sut.displayAds)
        XCTAssertNotNil(sut.adsUrl)
    }
    
    func testUpdateAdsSlot_configSameAdsSlotButDifferentDisplayAdsValue_shouldNotChangeURLButUpdateDisplayAdsValue() async {
        let currentAdsSlotConfig = randomAdsSlotConfig
        let expectedAdsSlotConfig = AdsSlotConfig(adsSlot: currentAdsSlotConfig.adsSlot,
                                                  displayAds: !currentAdsSlotConfig.displayAds)
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [currentAdsSlotConfig])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        let currentAdsUrl = sut.adsUrl
        await sut.updateAdsSlot(expectedAdsSlotConfig)
        
        XCTAssertEqual(currentAdsUrl, sut.adsUrl)
        XCTAssertEqual(expectedAdsSlotConfig.displayAds, sut.displayAds)
        XCTAssertNotNil(sut.adsUrl)
    }
    
    func testUpdateAdsSlot_differentAdsSlotConfig_shouldUpdateURLandDisplayAdsValue() async {
        let currentAdsSlotConfig = AdsSlotConfig(adsSlot: .files, displayAds: true)
        let expectedAdsSlotConfig = AdsSlotConfig(adsSlot: .home, displayAds: false)
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [currentAdsSlotConfig])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        let currentAdsUrl = sut.adsUrl
        await sut.updateAdsSlot(expectedAdsSlotConfig)
        
        XCTAssertNotEqual(currentAdsUrl, sut.adsUrl)
        XCTAssertEqual(expectedAdsSlotConfig.displayAds, sut.displayAds)
        XCTAssertNotNil(sut.adsUrl)
    }
    
    func testDidTapAdsContent_withNewAccount_closeAdsThenChangedTab_shouldNotShowAdsSlotAgainOnPreviousTab() async {
        let adsSlotConfigTabOne = AdsSlotConfig(adsSlot: .home, displayAds: true)
        let adsSlotConfigTabTwo = AdsSlotConfig(adsSlot: .files, displayAds: true)
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [adsSlotConfigTabOne])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList, isNewAccount: true)
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertTrue(sut.closedAds.isEmpty)
        
        await sut.didTapAdsContent()
        XCTAssertTrue(sut.closedAds.contains(adsSlotConfigTabOne.adsSlot))
        XCTAssertFalse(sut.displayAds)
        
        await sut.updateAdsSlot(adsSlotConfigTabTwo)
        XCTAssertTrue(sut.closedAds.contains(adsSlotConfigTabOne.adsSlot))
        XCTAssertFalse(sut.closedAds.contains(adsSlotConfigTabTwo.adsSlot))
        XCTAssertTrue(sut.displayAds)
        
        await sut.updateAdsSlot(adsSlotConfigTabOne)
        XCTAssertTrue(sut.closedAds.contains(adsSlotConfigTabOne.adsSlot))
        XCTAssertFalse(sut.closedAds.contains(adsSlotConfigTabTwo.adsSlot))
        XCTAssertFalse(sut.displayAds)
    }
    
    func testDidTapAdsContent_withExistingAccount_shouldLoadNewAdsAndDontCloseAdsSlot() async {
        let adsSlotConfigCurrentTab = AdsSlotConfig(adsSlot: .home, displayAds: true)
        let stream = makeMockAdsSlotChangeStream(adsSlotConfigs: [adsSlotConfigCurrentTab])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList, isNewAccount: false)
        await sut.setupABTestVariant()
        sut.monitorAdsSlotChanges()
        await sut.monitorAdsSlotChangesTask?.value
        
        XCTAssertTrue(sut.closedAds.isEmpty)
        
        await sut.didTapAdsContent()
        XCTAssertTrue(sut.closedAds.isEmpty)
        XCTAssertTrue(sut.displayAds)
        XCTAssertNotNil(sut.adsUrl)
    }
    
    // MARK: Helper
    private func makeSUT(
        adsSlotChangeStream: any AdsSlotChangeStreamProtocol = MockAdsSlotChangeStream(),
        adsList: [String: String] = [:],
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: true],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA]),
        isNewAccount: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        
        let adsUseCase = MockAdsUseCase(adsList: adsList)
        let accountUseCase = MockAccountUseCase(isNewAccount: isNewAccount)
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        
        let sut = AdsSlotViewModel(adsUseCase: adsUseCase, 
                                   accountUseCase: accountUseCase,
                                   adsSlotChangeStream: adsSlotChangeStream,
                                   featureFlagProvider: featureFlagProvider,
                                   abTestProvider: abTestProvider)
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
    
    private var adsList = [AdsSlotEntity.files.rawValue: "https://testAd/newLink-files",
                           AdsSlotEntity.photos.rawValue: "https://testAd/newLink-photos",
                           AdsSlotEntity.home.rawValue: "https://testAd/newLink-home",
                           AdsSlotEntity.sharedLink.rawValue: "https://testAd/newLink-sharedLink"]

    private var randomAdsSlotConfig: AdsSlotConfig {
        let adsSlot: AdsSlotEntity = [.files, .home, .photos, .sharedLink].randomElement() ?? .files
        return AdsSlotConfig(adsSlot: adsSlot, displayAds: Bool.random())
    }
}
