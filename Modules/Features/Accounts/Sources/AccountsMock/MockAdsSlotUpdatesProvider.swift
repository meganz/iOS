import Accounts
import MEGADomain
import MEGASwift

public final class MockAdsSlotUpdatesProvider: AdsSlotUpdatesProviderProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?>
    
    public init(adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.adsSlotUpdates = adsSlotUpdates
    }
}
