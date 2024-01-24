import Accounts
import Combine
@testable import MEGA
import XCTest

final class MainTabBarAdsViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private func isAdsCookieEnabled() async -> Bool {
        true
    }
    
    func testAdsSlotConfigPublisher_shouldMatchPublishedConfig() throws {
        var configList = [nil,
                          AdsSlotConfig(adsSlot: .files, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled),
                          AdsSlotConfig(adsSlot: .home, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled),
                          nil,
                          AdsSlotConfig(adsSlot: .photos, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled),
                          AdsSlotConfig(adsSlot: .sharedLink, displayAds: true, isAdsCookieEnabled: isAdsCookieEnabled)]
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
