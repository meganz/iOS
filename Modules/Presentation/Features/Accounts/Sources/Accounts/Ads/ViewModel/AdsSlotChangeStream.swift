import Combine
import MEGADomain
import UIKit

// This procotol is for ViewController where the ads slots will be added.
// It will provide the current ads slot type for the ViewController.
public protocol AdsSlotViewControllerProtocol {
    func currentAdsSlotType() -> AdsSlotEntity?
}

// This protocol will handle sending new Ads Slot changes.
// Ads Slot is the type of container where the ads will be added in the view.
// Loading Ads content is depending on their ads slot type.
public protocol AdsSlotChangeStreamProtocol {
    var adsSlotStream: AsyncStream<AdsSlotEntity?>? { get }
}

public final class AdsSlotChangeStream: AdsSlotChangeStreamProtocol {
    private var subscriptions = Set<AnyCancellable>()
    private var continuation: AsyncStream<AdsSlotEntity?>.Continuation!
    public var adsSlotStream: AsyncStream<AdsSlotEntity?>?
    
    public init(adsSlotViewController: any AdsSlotViewControllerProtocol) {
        adsSlotStream = AsyncStream(AdsSlotEntity?.self) { continuation in
            self.continuation = continuation
        }
        
        if let tabController = adsSlotViewController as? UITabBarController {
            setUpTabBarSubscription(tabBar: tabController,
                                    adsSlotVC: adsSlotViewController)
        } else {
            continuation.yield(adsSlotViewController.currentAdsSlotType())
        }
    }
    
    deinit {
        continuation.finish()
        subscriptions.removeAll()
    }
    
    // MARK: MainTabBar
    private func setUpTabBarSubscription(tabBar: UITabBarController, adsSlotVC: any AdsSlotViewControllerProtocol) {
        tabBar.publisher(for: \.selectedViewController)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                continuation.yield(adsSlotVC.currentAdsSlotType())
            }
            .store(in: &subscriptions)
    }
}
