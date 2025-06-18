import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: UIViewRepresentable {
    private let adMob: AdMob
    let adSize: AdSize
    private var bannerViewDidReceiveAdsUpdate: ((Result<Void, any Error>) -> Void)?
    
    init(
        adSize: AdSize,
        adMob: AdMob,
        bannerViewDidReceiveAdsUpdate: ((Result<Void, any Error>) -> Void)?
    ) {
        self.adSize = adSize
        self.adMob = adMob
        self.bannerViewDidReceiveAdsUpdate = bannerViewDidReceiveAdsUpdate
    }
    
    func makeUIView(context: Context) -> some UIView {
        // Wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        let bannerView = context.coordinator.bannerView
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }
    
    func makeCoordinator() -> AdMobBannerCoordinator {
        AdMobBannerCoordinator(self)
    }
    
    @MainActor
    final class AdMobBannerCoordinator: NSObject, BannerViewDelegate {
        private(set) lazy var bannerView: BannerView = {
            let banner = BannerView(adSize: parent.adSize)
            banner.adUnitID = parent.adMob.unitID
            banner.load(Request())
            banner.delegate = self
            return banner
        }()
        
        private let parent: AdMobBannerView
        
        init(_ parent: AdMobBannerView) {
            self.parent = parent
            super.init()
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.bannerViewDidReceiveAdsUpdate?(.success)
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            parent.bannerViewDidReceiveAdsUpdate?(.failure(error))
        }
    }
}
