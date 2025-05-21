import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASdk
import MEGASwift

extension MEGAAVViewController {
    
    @objc func makeViewModel() -> AVViewModel {
        AVViewModel()
    }

    @objc func bindToSubscriptions(
        movieStalled: (() -> Void)?
    ) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        let notificationCenter = NotificationCenter.default
        
        notificationCenter
            .publisher(for: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.movieFinishedCallback() }
            .store(in: &subscriptions)
        
        Publishers
            .Merge(
                notificationCenter.publisher(for: .reachabilityChanged),
                notificationCenter.publisher(for: UIApplication.willEnterForegroundNotification))
            .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: false)
            .sink(receiveValue: { [weak self] _ in self?.checkNetworkChanges() })
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in self?.applicationDidEnterBackground() })
            .store(in: &subscriptions)
        
        notificationCenter
            .publisher(for: NSNotification.Name.AVPlayerItemPlaybackStalled, object: player?.currentItem)
            .receive(on: DispatchQueue.main)
            .sink { _ in movieStalled?() }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }
    
    @objc func movieStalledCallback() {
        playerDidStall()
    }
    
    @objc func bindPlayerTimeControlStatus() -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        
        player?.publisher(for: \.timeControlStatus)
            .sink { [weak self] in self?.playerDidChangeTimeControlStatus($0) }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }

    @objc func bindPlayerItemStatus(playerItem: AVPlayerItem) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()

        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .failed: logError(for: playerItem)
                default: break
                }

                didChangePlayerItemStatus(status)
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
    
    // MARK: - Loading Indicator
    
    @objc func configureActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = UIColor.whiteFFFFFF
        activityIndicator.hidesWhenStopped = true
        
        addLoadingViewAsVideoPlayerSubview(activityIndicator)
    }
    
    private func addLoadingViewAsVideoPlayerSubview(_ activityIndicator: UIActivityIndicatorView) {
        guard let contentOverlayView else { return }
        
        contentOverlayView.addSubview(activityIndicator)
        contentOverlayView.bringSubviewToFront(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentOverlayView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentOverlayView.centerYAnchor)
        ])
    }
    
    @objc func willStartPlayer() {
        startLoading()
    }
    
    @objc func didChangePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .unknown, .readyToPlay, .failed:
            stopLoading()
        default:
            break
        }
    }
    
    @objc func playerDidStall() {
        startLoading()
    }
    
    @objc func playerDidChangeTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        handleLoadingViewOnChangeTimeControlStatus(status)
        trackAnalytics(for: status, tracker: DIContainer.tracker)
        
        if case .playing = status {
            hasPlayedOnceBefore = true
        }
    }
    
    private func handleLoadingViewOnChangeTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .waitingToPlayAtSpecifiedRate:
            startLoading()
        default:
            stopLoading()
        }
    }
    
    private func startLoading() {
        activityIndicator.startAnimating()
    }
    
    private func stopLoading() {
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Analytics
    
    func trackAnalytics(for status: AVPlayer.TimeControlStatus, tracker: some AnalyticsTracking) {
        switch status {
        case .playing:
            guard !hasPlayedOnceBefore else { return }
            
            tracker.trackAnalyticsEvent(with: VideoPlayerIsActivatedEvent())
        default:
            break
        }
    }
    
    // MARK: - PlayerItemMetadata for now playing info
        
    @objc func setPlayerItemMetadata(playerItem: AVPlayerItem, node: MEGANode) {
        Task { @MainActor in
            let command = SetVideoPlayerItemMetadataCommand(playerItem: playerItem, node: node)
            await command.execute()
        }
    }
    
    // MARK: - Notifications
    
    private func movieFinishedCallback() {
        isEndPlaying = true
        replayVideo()
    }
    
    private func replayVideo() {
        guard let player else { return }
        player.seek(to: CMTime.zero)
        player.play()
        isEndPlaying = false
    }
    
    private func applicationDidEnterBackground() {
        if
            let keyWindow = UIApplication.mnz_keyWindow(),
            NSStringFromClass(type(of: keyWindow)) != "UIWindow" {
            UserDefaults.standard.set(true, forKey: "presentPasscodeLater")
        }
    }

    private func checkNetworkChanges() {
        MEGALogDebug(
                    """
                    [MEGAAVViewController] Network changed - : isReachableViaWWAN: \(String(describing: MEGAReachabilityManager.isReachableViaWWAN))
                    isReachableViaWiFi: \(String(describing: MEGAReachabilityManager.isReachableViaWiFi))
                    hasCellularConnection: \(String(describing: MEGAReachabilityManager.hasCellularConnection))
                    """
        )

        guard let apiForStreaming,
              MEGAReachabilityManager.isReachable(), let node, let fileUrl else { return }
        let oldFileURL = fileUrl
        setFileUrl(apiForStreaming: apiForStreaming, node: node)

        if oldFileURL != fileUrl {
            MEGALogDebug("[MEGAAVViewController] fileUrl changed from \(oldFileURL) to \(fileUrl)")
            let currentTime = self.player?.currentTime()
            let newPlayerItem = AVPlayerItem(url: fileUrl)
            setPlayerItemMetadata(playerItem: newPlayerItem, node: node)
            self.player?.replaceCurrentItem(with: newPlayerItem)
            
            guard let currentTime, currentTime.isValid else { return }
            self.player?.seek(to: currentTime)
        }
    }
    
    private func setFileUrl(apiForStreaming: MEGASdk, node: MEGANode) {
        MEGALogDebug("[MEGAAVViewController]: setFileUrl with node: \(node)")
        if apiForStreaming.httpServerIsLocalOnly() {
            guard let url = apiForStreaming.httpServerGetLocalLink(node) else { return }
            MEGALogDebug("[MEGAAVViewController]: setFileUrl with apiForStreaming.httpServerIsLocalOnly result: \(url)")
            fileUrl = url
        } else {
            guard let url = apiForStreaming.httpServerGetLocalLink(node)?.updatedURLWithCurrentAddress() else { return }
            MEGALogDebug("[MEGAAVViewController]: setFileUrl updatedURLWithCurrentAddress result: \(url)")
            fileUrl = url
        }
    }

    private func logError(for playerItem: AVPlayerItem) {
        guard let error = playerItem.error else { return }
        MEGALogError("[MEGAAVViewController] Could play media \(playerItem) because of error: \(error)")
    }

    @objc func streamingPath(node: MEGANode) -> URL? {
        guard let apiForStreaming else { return nil }
        let streamingInfoRepository = StreamingInfoRepository(sdk: apiForStreaming)
        let streamingInfoUseCase = StreamingInfoUseCase(streamingInfoRepository: streamingInfoRepository)
        let path = streamingInfoUseCase.path(fromNode: node)
        return path
    }
    
    @objc func checkIsFileViolatesTermsOfService() {
        guard let node else { return }
        Task {
            let nodeInfoUseCase = NodeInfoUseCase()
            let isTakenDown = try await nodeInfoUseCase.isTakenDown(node: node, isFolderLink: isFolderLink)
            if isTakenDown {
                showTermsOfServiceAlert()
            }
        }
    }
    
    @MainActor
    private func showTermsOfServiceAlert() {
        let alertController = UIAlertController(
            title: Strings.Localizable.General.Alert.TermsOfServiceViolation.title,
            message: Strings.Localizable.fileLinkUnavailableText2,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: Strings.Localizable.dismiss, style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }))
        present(alertController, animated: true)
    }
    
    @objc func configureViewColor() {
        view.backgroundColor = TokenColors.Background.page
    }
    
    @objc func saveRecentlyWatchedVideo(destination: NSNumber, timescale: NSNumber?) {
        let repository = RecentlyOpenedNodesRepository(store: MEGAStore.shareInstance(), sdk: MEGASdk.shared)
        let useCase = RecentlyOpenedNodesUseCase(recentlyOpenedNodesRepository: repository)
        
        guard let video = node?.toNodeEntity(), video.fileExtensionGroup.isVideo else { return }
        let mediaDestination = MediaDestinationEntity(fingerprint: fileFingerprint(), destination: destination.intValue, timescale: timescale?.intValue)
        let recentlyWatchedVideo = RecentlyOpenedNodeEntity(node: video, lastOpenedDate: Date.now, mediaDestination: mediaDestination)
        do {
            try useCase.saveNode(recentlyOpenedNode: recentlyWatchedVideo)
        } catch {
            MEGALogError("Failed to save recently opened node from: \(MEGAAVViewController.self)")
        }
    }
}
