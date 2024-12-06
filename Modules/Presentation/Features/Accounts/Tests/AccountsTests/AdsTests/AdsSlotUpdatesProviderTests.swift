import Accounts
import MEGASwift
import Testing

struct AdsSlotUpdatesProviderTests {
    
    // MARK: - Helpers
    private final class TestAdsSlotViewController: AdsSlotViewControllerProtocol {
        private let stream: AsyncStream<AdsSlotConfig?>
        private let continuation: AsyncStream<AdsSlotConfig?>.Continuation?
        
        var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
            stream.eraseToAnyAsyncSequence()
        }
        
        init() {
            (stream, continuation) = AsyncStream<AdsSlotConfig?>.makeStream()
        }
        
        func yield(_ config: AdsSlotConfig?) {
            continuation?.yield(config)
        }
    }
    
    // MARK: - Test
    @MainActor
    @Test("Should provide correct ads slot updates")
    func adsSlotUpdates() async throws {
        let controller = TestAdsSlotViewController()
        let sut = AdsSlotUpdatesProvider(adsSlotViewController: controller)
        
        let configs = [
            AdsSlotConfig(adsSlot: .files, displayAds: true),
            AdsSlotConfig(adsSlot: .home, displayAds: true),
            nil
        ]
        
        let task = Task {
            var receivedConfigs: [AdsSlotConfig?] = []
            for await config in sut.adsSlotUpdates {
                receivedConfigs.append(config)
            }
            return receivedConfigs
        }
        
        // Send each ads config
        for config in configs {
            try await Task.sleep(nanoseconds: 100_000_000)
            controller.yield(config)
        }
        task.cancel()
        
        let receivedConfigs = await task.value
        #expect(receivedConfigs == configs)
    }
}
