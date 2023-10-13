import Accounts
import Combine

final class MainTabBarAdsViewModel {
    private let adsSlotConfigSourcePublisher: PassthroughSubject<AdsSlotConfig?, Never>
    let adsSlotConfigPublisher: AnyPublisher<AdsSlotConfig?, Never>
    
    init(adsSlotConfigSourcePublisher: PassthroughSubject<AdsSlotConfig?, Never>) {
        self.adsSlotConfigSourcePublisher = adsSlotConfigSourcePublisher
        self.adsSlotConfigPublisher = AnyPublisher(adsSlotConfigSourcePublisher).eraseToAnyPublisher()
    }
    
    func sendNewAdsConfig(_ config: AdsSlotConfig?) {
        adsSlotConfigSourcePublisher.send(config)
    }
}
