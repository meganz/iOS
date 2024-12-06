import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: View {
    private let adMob: AdMob
    private let adSize = GADAdSizeBanner
    
    init(adMob: AdMob) {
        self.adMob = adMob
    }
    
    var body: some View {
        AdMobBannerContentView(
            adSize: adSize,
            adMob: adMob
        )
        .frame(height: adSize.size.height)
    }
}

struct AdMobBannerContentView: UIViewRepresentable {
    private let adMob: AdMob
    let adSize: GADAdSize
    
    init(
        adSize: GADAdSize,
        adMob: AdMob
    ) {
        self.adSize = adSize
        self.adMob = adMob
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
    final class AdMobBannerCoordinator: NSObject {
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            banner.adUnitID = parent.adMob.unitID
            banner.load(GADRequest())
            return banner
        }()
        
        private let parent: AdMobBannerContentView
        
        init(_ parent: AdMobBannerContentView) {
            self.parent = parent
            super.init()
        }
    }
}
