import Combine
import MEGADomain
import UIKit

// This procotol is for ViewController where the ads slots will be added.
// It will publish the new ads slot configuration of the ViewController.
public protocol AdsSlotViewControllerProtocol {
    var adsSlotPublisher: AnyPublisher<AdsSlotConfig?, Never> { get }
}

// This protocol will handle sending new Ads Slot configuration changes.
// Ads Slot is the ads container that will be added in the view.
// Loading Ads content is depending on their ads slot configuration - ads slot type and displayAds.
public protocol AdsSlotChangeStreamProtocol {
    var adsSlotStream: AsyncStream<AdsSlotConfig?> { get }
}

public final class AdsSlotChangeStream: AdsSlotChangeStreamProtocol {
    private var subscriptions = Set<AnyCancellable>()
    public let (adsSlotStream, continuation) = AsyncStream
        .makeStream(of: AdsSlotConfig?.self, bufferingPolicy: .bufferingNewest(1))

    public init(adsSlotViewController: any AdsSlotViewControllerProtocol) {
        adsSlotViewController.adsSlotPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                continuation.yield(newValue)
        }
        .store(in: &subscriptions)
    }
    
    deinit {
        continuation.finish()
        subscriptions.removeAll()
    }
}
