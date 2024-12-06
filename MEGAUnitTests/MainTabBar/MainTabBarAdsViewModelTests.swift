@preconcurrency import Accounts
@testable import MEGA
import Testing

struct MainTabBarAdsViewModelTests {
    @Test("Should receive correct ads slot configs", .timeLimit(.minutes(1)))
    func sendNewAdsConfig() async throws {
        let sut = MainTabBarAdsViewModel()
        let configs = [
            AdsSlotConfig(adsSlot: .files, displayAds: true),
            AdsSlotConfig(adsSlot: .home, displayAds: true),
            nil
        ]
        
        let task = Task {
            var receivedConfigs: [AdsSlotConfig?] = []
            for await config in sut.adsSlotConfigAsyncSequence {
                receivedConfigs.append(config)
            }
            return receivedConfigs
        }
        
        // Send each ads config
        for config in configs {
            try await Task.sleep(nanoseconds: 100_000_000)
            sut.sendNewAdsConfig(config)
        }
        task.cancel()
        
        let receivedConfigs = await task.value
        #expect(receivedConfigs == configs)
    }
}
