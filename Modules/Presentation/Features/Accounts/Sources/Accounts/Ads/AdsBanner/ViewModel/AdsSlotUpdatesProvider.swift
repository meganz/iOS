import MEGASwift
import UIKit

// This procotol is for ViewController where the ads slots will be added.
// It will publish the new ads slot configuration of the ViewController.
public protocol AdsSlotViewControllerProtocol {
    var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> { get }
}

// This protocol will handle sending new Ads Slot configuration changes.
// Ads Slot is the ads container that will be added in the view.
// Loading Ads content is depending on their ads slot configuration - ads slot type and displayAds.
public protocol AdsSlotUpdatesProviderProtocol {
    var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> { get }
}

public final class AdsSlotUpdatesProvider: AdsSlotUpdatesProviderProtocol {
    private let adsSlotViewController: any AdsSlotViewControllerProtocol

    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        adsSlotViewController.adsSlotUpdates
    }
    
    public init(adsSlotViewController: some AdsSlotViewControllerProtocol) {
        self.adsSlotViewController = adsSlotViewController
    }
}
