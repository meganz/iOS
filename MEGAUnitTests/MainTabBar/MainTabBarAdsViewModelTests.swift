import Accounts
import Combine
@testable import MEGA
import XCTest

final class MainTabBarAdsViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testAdsSlotConfigPublisher_shouldMatchPublishedConfig() throws {
        var configList = [nil,
                          AdsSlotConfig(adsSlot: .files, displayAds: true),
                          AdsSlotConfig(adsSlot: .home, displayAds: true),
                          nil,
                          AdsSlotConfig(adsSlot: .photos, displayAds: true),
                          AdsSlotConfig(adsSlot: .sharedLink, displayAds: true)]
        let sut = MainTabBarAdsViewModel(adsSlotConfigSourcePublisher: PassthroughSubject<AdsSlotConfig?, Never>())
        
        sut.adsSlotConfigPublisher
            .sink { config in
                XCTAssertEqual(config, configList.removeFirst())
            }
            .store(in: &subscriptions)
        
        configList.forEach { config in
            sut.sendNewAdsConfig(config)
        }
    }
}
