import Accounts
import MEGASwift

final class MainTabBarAdsViewModel {
    private var continuation: AsyncStream<AdsSlotConfig?>.Continuation?
    private var latestConfig: AdsSlotConfig?
    
    /// The tab bar sends a new config every time the screen on show changes, which it has already done
    /// by the time the app has finished launching: the first tab reports itself as it appears. A listener
    /// that starts after that would otherwise wait for the next change(a tab switch) to hear anything
    /// at all, so the stream opens with the config the tab bar is on now.
    var adsSlotConfigAsyncSequence: AnyAsyncSequence<AdsSlotConfig?> {
        let (stream, continuation) = AsyncStream.makeStream(of: AdsSlotConfig?.self, bufferingPolicy: .bufferingNewest(1))
        self.continuation?.finish()
        self.continuation = continuation
        
        if let latestConfig {
            continuation.yield(latestConfig)
        }
        
        return stream.eraseToAnyAsyncSequence()
    }
    
    func sendNewAdsConfig(_ config: AdsSlotConfig?) {
        latestConfig = config
        continuation?.yield(config)
    }
}
