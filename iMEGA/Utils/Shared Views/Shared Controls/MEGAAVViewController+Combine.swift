import Combine
import Foundation
import MEGADomain

extension MEGAAVViewController {
    
    @objc func bindToSubscriptions(
        movieFinished: (() -> Void)?,
        checkNetworkChanges: (() -> Void)?,
        applicationDidEnterBackground: (() -> Void)?,
        movieStalled: (() -> Void)?
    ) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        let notificationCenter = NotificationCenter.default
        
        notificationCenter
            .publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in movieFinished?() }
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
        
        notificationCenter
            .publisher(for: NSNotification.Name.AVPlayerItemPlaybackStalled, object: player?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in movieStalled?() }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }

    @objc func movieStalledCallback() {
        avViewControllerDelegate?.playerDidStall?()
    }
    
    @objc func bindPlayerTimeControlStatus() -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        
        player?.publisher(for: \.timeControlStatus)
            .sink { [weak self] in self?.avViewControllerDelegate?.playerDidChangeTimeControlStatus?($0) }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }
    
    @objc func bindPlayerItemStatus(playerItem: AVPlayerItem) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay: player?.play()
                default: break
                }
                avViewControllerDelegate?.didChangePlayerItemStatus?(status)
            }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }
    
    @objc func seekTo(mediaDestination: MOMediaDestination?) {
        guard let mediaDestination = mediaDestination else {
            player?.seek(to: CMTimeMake(value: 0, timescale: 1))
            return
        }
        
        let time = CMTimeMake(value: mediaDestination.destination as? Int64 ?? 0, timescale: mediaDestination.timescale as? Int32 ?? 0)
        if CMTIME_IS_VALID(time) {
            player?.seek(to: time)
        }
    }
    
    @objc func deallocPlayer() {
        cancelPlayerProcess()
        player = nil
    }
    
    @objc func cancelPlayerProcess() {
        player?.pause()
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()
    }
}
