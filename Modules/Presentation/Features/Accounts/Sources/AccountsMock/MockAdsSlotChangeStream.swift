import Accounts
import Combine
import MEGADomain

public final class MockAdsSlotChangeStream: AdsSlotChangeStreamProtocol {
    public var adsSlotStream: AsyncStream<AdsSlotEntity?>?
    
    public init(adsSlotStream: AsyncStream<AdsSlotEntity?>? = nil) {
        self.adsSlotStream = adsSlotStream
    }
}
