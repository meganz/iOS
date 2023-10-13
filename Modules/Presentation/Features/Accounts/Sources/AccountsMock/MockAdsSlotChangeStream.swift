import Accounts
import Combine
import MEGADomain

public final class MockAdsSlotChangeStream: AdsSlotChangeStreamProtocol {
    public var adsSlotStream: AsyncStream<AdsSlotConfig?>
    
    public init(adsSlotStream: AsyncStream<AdsSlotConfig?> = AsyncStream<AdsSlotConfig?> { $0.finish() }) {
        self.adsSlotStream = adsSlotStream
    }
}
