import Combine
import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: View {
    private let refreshAdsPublisher: AnyPublisher<Void, Never>
    private let adMob: AdMob
    
    init(
        refreshAdsPublisher: AnyPublisher<Void, Never>,
        adMob: AdMob
    ) {
        self.refreshAdsPublisher = refreshAdsPublisher
        self.adMob = adMob
    }
    
    var body: some View {
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)
            
            AdMobBannerContentView(
                adSize: adSize,
                adMob: adMob,
                refreshAdsPublisher: refreshAdsPublisher
            )
            .frame(height: adSize.size.height)
        }
    }
}

struct AdMobBannerContentView: UIViewRepresentable {
    private let refreshAdsPublisher: AnyPublisher<Void, Never>
    private let adMob: AdMob
    let adSize: GADAdSize
    
    init(
        adSize: GADAdSize,
        adMob: AdMob,
        refreshAdsPublisher: AnyPublisher<Void, Never>
    ) {
        self.adSize = adSize
        self.adMob = adMob
        self.refreshAdsPublisher = refreshAdsPublisher
    }
    
    func makeUIView(context: Context) -> some UIView {
        // Wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> AdMobBannerCoordinator {
        AdMobBannerCoordinator(self, refreshAdsPublisher: refreshAdsPublisher)
    }
    
    final class AdMobBannerCoordinator: NSObject {
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            banner.adUnitID = parent.adMob.unitID
            banner.load(GADRequest())
            return banner
        }()
        
        private let parent: AdMobBannerContentView
        private let refreshAdsPublisher: AnyPublisher<Void, Never>
        private var subscriptions = Set<AnyCancellable>()
        
        init(
            _ parent: AdMobBannerContentView,
            refreshAdsPublisher: AnyPublisher<Void, Never>
        ) {
            self.parent = parent
            self.refreshAdsPublisher = refreshAdsPublisher
            super.init()
            
            setupSubscription()
        }
        
        private func setupSubscription() {
            refreshAdsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.refreshAds()
                }
                .store(in: &subscriptions)
        }
        
        private func refreshAds() {
            bannerView.load(GADRequest())
        }
    }
}
