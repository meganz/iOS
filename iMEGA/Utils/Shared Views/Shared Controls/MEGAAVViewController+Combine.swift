import Foundation
import Combine
import MEGADomain

extension MEGAAVViewController {
    
    @objc func bindToSubscriptions(movieFinised: (() -> Void)?, checkNetworkChanges: (() -> Void)?, applicationDidEnterBackground: (() -> Void)?) -> NSSet {
        var subscriptions = Set<AnyCancellable>()
        let notificationCenter = NotificationCenter.default
        
        notificationCenter
            .publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in movieFinised?() }
            .store(in: &subscriptions)
        
        Publishers
            .Merge(
                notificationCenter.publisher(for: .reachabilityChanged),
                notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification))
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: false)
            .sink(receiveValue: { _ in checkNetworkChanges?() })
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { _ in applicationDidEnterBackground?() })
            .store(in: &subscriptions)
        
        return NSSet(set: subscriptions)
    }
}
