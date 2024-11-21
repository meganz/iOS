import Accounts
import MEGASwift

final class MainTabBarAdsViewModel {
    private var continuation: AsyncStream<AdsSlotConfig?>.Continuation?
    
    var adsSlotConfigAsyncSequence: AnyAsyncSequence<AdsSlotConfig?> {
        let (stream, continuation) = AsyncStream.makeStream(of: AdsSlotConfig?.self, bufferingPolicy: .bufferingNewest(1))
        self.continuation?.finish()
        self.continuation = continuation
        return stream.eraseToAnyAsyncSequence()
    }
    
    func sendNewAdsConfig(_ config: AdsSlotConfig?) {
        continuation?.yield(config)
    }
}
