import Combine
@testable import MEGA
import MEGADomain

final class MockAdsSlotChangeStream: AdsSlotChangeStreamProtocol {
    var adsSlotStream: AsyncStream<AdsSlotEntity?>?
    
    init(adsSlotStream: AsyncStream<AdsSlotEntity?>? = nil) {
        self.adsSlotStream = adsSlotStream
    }
}
