import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class AdsSlotViewModelTests: XCTestCase {
    var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Feature flag
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsEnabled_shouldBeEnabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: true])
        XCTAssertTrue(sut.isFeatureFlagForInAppAdsEnabled)
    }
    
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsDisabled_shouldBeEnabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: false])
        XCTAssertFalse(sut.isFeatureFlagForInAppAdsEnabled)
    }

    // MARK: - Ads slot
    func testLoadAdsForAdsSlot_featureFlagEnabled_shouldHaveNewUrlAndDisplayAds() async {
        let expectedAdsSlot = randomAdsSlot
        let expectedAdsUrl = adsList[expectedAdsSlot.rawValue]
        let stream = makeMockAdsSlotChangeStream(adsSlots: [expectedAdsSlot])
        
        let sut = makeSUT(adsSlotChangeStream: stream,
                          adsList: adsList,
                          featureFlags: [.inAppAds: true])
        
        await sut.monitorAdsSlotChanges()
        
        XCTAssertNotNil(sut.adsUrl)
        XCTAssertEqual(sut.adsUrl?.absoluteString, expectedAdsUrl)
        XCTAssertTrue(sut.displayAds)
    }

    func testLoadAdsForAdsSlot_featureFlagDisabled_shouldHaveNilUrlAndDontDisplayAds() async {
        let stream = makeMockAdsSlotChangeStream(adsSlots: [randomAdsSlot])
        let sut = makeSUT(adsSlotChangeStream: stream,
                          adsList: adsList,
                          featureFlags: [.inAppAds: false])
        
        await sut.monitorAdsSlotChanges()
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testLoadAdsForAdsSlot_noAds_shouldHaveNilUrlAndDontDisplayAds() async {
        let stream = makeMockAdsSlotChangeStream(adsSlots: [nil])
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: adsList)
        
        await sut.monitorAdsSlotChanges()
        
        XCTAssertNil(sut.adsUrl)
        XCTAssertFalse(sut.displayAds)
    }
    
    func testLoadAdsForAdsSlotList_shouldMatchAdsUrl() async {
        var adsSlots: [AdsSlotEntity] = [.files, .home, .photos, .sharedLink]
        let stream = makeMockAdsSlotChangeStream(adsSlots: adsSlots)
        let ads = adsList
        let sut = makeSUT(adsSlotChangeStream: stream, adsList: ads)
    
        sut.$adsUrl
            .dropFirst()
            .sink { url in
                let adsSlot = adsSlots.removeFirst()
                XCTAssertEqual(url?.absoluteString, ads[adsSlot.rawValue])
            }
            .store(in: &subscriptions)
        
        await sut.monitorAdsSlotChanges()
    }

    // MARK: Helper
    private func makeSUT(
        adsSlotChangeStream: any AdsSlotChangeStreamProtocol = MockAdsSlotChangeStream(),
        adsList: [String: String] = [:],
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: true],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AdsSlotViewModel {
        
        let adsUseCase = MockAdsUseCase(adsList: adsList)
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        
        let sut = AdsSlotViewModel(adsUseCase: adsUseCase,
                                   adsSlotChangeStream: adsSlotChangeStream,
                                   featureFlagProvider: featureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeMockAdsSlotChangeStream(adsSlots: [AdsSlotEntity?]) -> MockAdsSlotChangeStream {
        let adsSlotStream = AsyncStream<AdsSlotEntity?> { continuation in
            adsSlots.forEach { adsSlot in
                continuation.yield(adsSlot)
            }
            continuation.finish()
        }
        return MockAdsSlotChangeStream(adsSlotStream: adsSlotStream)
    }
    
    private var adsList = [AdsSlotEntity.files.rawValue: "https://testAd/newLink-files",
                           AdsSlotEntity.photos.rawValue: "https://testAd/newLink-photos",
                           AdsSlotEntity.home.rawValue: "https://testAd/newLink-home",
                           AdsSlotEntity.sharedLink.rawValue: "https://testAd/newLink-sharedLink"]
    
    private var randomAdsSlot: AdsSlotEntity {
        [.files, .home, .photos, .sharedLink].randomElement() ?? .files
    }
}
