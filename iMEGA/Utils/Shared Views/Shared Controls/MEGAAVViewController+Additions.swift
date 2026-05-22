import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAFoundation
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
    
    func replaceURLForAirPlay(activated: Bool) {
        guard player != nil, let fileUrl, let node else { return }
        
        if activated {
            let airPlayURL = fileUrl.updatedURLWithCurrentAddress()
            replacePlayerItemURL(to: airPlayURL, for: node)
        } else {
            replacePlayerItemURL(to: fileUrl, for: node)
        }
    }
    
    @objc func movieStalledCallback() {
        playerDidStall()
    }
    
    private func bindPlayerTimeControlStatus() -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        
        player?.publisher(for: \.timeControlStatus)
            .sink { [weak self] in self?.playerDidChangeTimeControlStatus($0) }
            .store(in: &subscriptions)
        
        return NSMutableSet(set: subscriptions)
    }
    
    private func bindPlayerItemStatus(playerItem: AVPlayerItem) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()
        
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .failed: logError(for: playerItem)
                case .readyToPlay: configureThrottleBitrate(for: playerItem)
                default: break
                }
                
                didChangePlayerItemStatus(status)
            }
            .store(in: &subscriptions)

        return NSMutableSet(set: subscriptions)
    }

    /// Configures the SDK's HTTP streaming server throttle for the given player item.
    ///
    /// Sums the estimated data rate of every audio and video track in the asset. When the
    /// total is above the high-bitrate floor (15 Mbps), a throttle scaled to the current
    /// playback rate is installed and a rate observer is registered so the throttle stays
    /// in sync with `AVPlayer.rate` changes. Below the floor, no throttle is installed.
    ///
    /// - Parameter playerItem: The player item whose asset bitrate determines the throttle.
    private func configureThrottleBitrate(for playerItem: AVPlayerItem) {
        guard apiForStreaming != nil else { return }
        Task {
            do {
                let asset = playerItem.asset
                var totalBitrate: Float = 0

                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                for track in videoTracks {
                    totalBitrate += try await track.load(.estimatedDataRate)
                }

                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                for track in audioTracks {
                    totalBitrate += try await track.load(.estimatedDataRate)
                }
                
                // bitrate throttle lower bound: 15_000_000 bps
                if totalBitrate > 15_000_000 {
                    applyThrottleBitrate(totalBitrate: totalBitrate, playbackRate: player?.rate ?? 1.0)
                    subscriptions.add(bindPlayerRateForThrottle(totalBitrate: totalBitrate))
                } else {
                    MEGALogInfo("[Throttle] Not high bitrate:\(totalBitrate), throttle not set")
                }
            } catch {
                MEGALogError("[Throttle] Failed to load tracks: \(error)")
            }
        }
    }

    /// Applies an HTTP streaming throttle of `totalBitrate × playbackRate × 3` bps to the SDK.
    ///
    /// The 3× headroom keeps the streaming server comfortably ahead of playback. `playbackRate`
    /// is clamped to a minimum of `1.0`
    ///
    /// - Parameters:
    ///   - totalBitrate: Combined estimated data rate of all media tracks, in bits per second.
    ///   - playbackRate: Current `AVPlayer.rate`; values below `1.0` are clamped to `1.0`.
    private func applyThrottleBitrate(totalBitrate: Float, playbackRate: Float) {
        guard let apiForStreaming, totalBitrate >= 0 else { return }
        let rate = max(playbackRate, 1.0)
        let throttleBps = UInt64(totalBitrate * rate * 3)
        apiForStreaming.httpServerSetThrottleBitrate(throttleBps)
        MEGALogInfo("[Throttle] Set throttle bitrate to \(throttleBps) bps (rate=\(rate) x3, total: \(Int64(totalBitrate)) bps)")
    }

    /// Observes `AVPlayer.rate` and re-applies the throttle whenever the playback rate changes.
    ///
    /// Only non-zero rates are forwarded, so pauses don't reset the throttle.
    ///
    /// - Parameter totalBitrate: Combined estimated data rate of all media tracks, in bits per second.
    /// - Returns: A set containing the rate-observer subscription; retain it to keep the binding alive.
    private func bindPlayerRateForThrottle(totalBitrate: Float) -> NSMutableSet {
        var subscriptions = Set<AnyCancellable>()

        player?.publisher(for: \.rate)
            .removeDuplicates()
            .filter { $0 > 0 } // only when playing
            .sink { [weak self] rate in
                self?.applyThrottleBitrate(totalBitrate: totalBitrate, playbackRate: rate)
            }
            .store(in: &subscriptions)

        return NSMutableSet(set: subscriptions)
    }
    
    private func bindPlayerExternalPlayback() -> NSSet {
        var subscriptions = Set<AnyCancellable>()
        player?.publisher(for: \.isExternalPlaybackActive)
            .removeDuplicates()
            .scan((old: false, new: false)) { state, value in
                (old: state.new, new: value)
            }
            .dropFirst()
            .sink { [weak self] state in
                guard state.old != state.new else { return }
                MEGALogInfo("Airplay active: \(state.new),\(self?.player?.isExternalPlaybackActive ?? false)")
                if state.new {
                    DIContainer.tracker.trackAnalyticsEvent(with: AirplayActivationInVideoPlaybackEvent())
                }
                guard let self, let player else { return }
                let isPlaying = player.rate > 0
                player.pause()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.replaceURLForAirPlay(activated: state.new)
                    if isPlaying {
                        self.player?.play()
                    }
                }
            }
            .store(in: &subscriptions)
        return NSSet(set: subscriptions)
    }
    
    private func seekTo(mediaDestination: MOMediaDestination?, playerItem: AVPlayerItem) {
        guard let mediaDestination else {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
            return
        }
        
        let time = CMTimeMake(value: mediaDestination.destination as? Int64 ?? 0, timescale: mediaDestination.timescale as? Int32 ?? 0)
        if CMTIME_IS_VALID(time) {
            playerItem.seek(to: time, completionHandler: nil)
        }
    }
    
    @objc func deallocPlayer() {
        cancelPlayerProcess()
        // Reset throttle so it doesn't affect next video
        apiForStreaming?.httpServerSetThrottleBitrate(0)
        player = nil
        subscriptions.removeAllObjects()
    }
    
    @objc func cancelPlayerProcess() {
        player?.pause()
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()
        player?.replaceCurrentItem(with: nil)
    }
    
    // MARK: - Loading Indicator
    
    @objc func configureActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = MEGAAssets.UIColor.whiteFFFFFF
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
    
    func startLoading() {
        activityIndicator.startAnimating()
    }
    
    private func stopLoading() {
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Analytics
    @objc func recordVideoPlaybackStartTime() {
        startTimeStamp = Date().timeIntervalSince1970
    }
    
    @objc func trackVideoPlaybackEndTime() {
        let delta = Date().timeIntervalSince1970 - startTimeStamp
        let clamped = min(max(0, delta), Double(Int32.max))
        DIContainer.tracker.trackAnalyticsEvent(with: VideoPlaybackRecordEvent(duration: Int32(clamped)))
    }
    
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
            replacePlayerItemURL(to: fileUrl, for: node)
        }
    }
    
    private func replacePlayerItemURL(to fileUrl: URL, for node: MEGANode) {
        MEGALogDebug("[MEGAAVViewController]: playeritem url replaced to: \(fileUrl)")
        let currentTime = self.player?.currentTime()
        let newPlayerItem = AVPlayerItem(url: fileUrl)
        setPlayerItemMetadata(playerItem: newPlayerItem, node: node)
        self.player?.replaceCurrentItem(with: newPlayerItem)
        
        guard let currentTime, currentTime.isValid else { return }
        self.player?.seek(to: currentTime)
    }
    
    private func setFileUrl(apiForStreaming: MEGASdk, node: MEGANode) {
        MEGALogDebug("[MEGAAVViewController]: setFileUrl with node: \(node)")
        guard let url = apiForStreaming.httpServerGetLocalLink(node) else { return }
        MEGALogDebug("[MEGAAVViewController]: setFileUrl with apiForStreaming.httpServerIsLocalOnly: \(apiForStreaming.httpServerIsLocalOnly()) result: \(url)")
        fileUrl = url
    }
    
    private func logError(for playerItem: AVPlayerItem) {
        guard let error = playerItem.error else { return }
        MEGALogError("[MEGAAVViewController] Could play media \(playerItem) because of error: \(error)")
    }
    
    @objc func streamingPath(node: MEGANode) -> URL? {
        guard let apiForStreaming else { return nil }
        let streamingInfoRepository = StreamingInfoRepository(sdk: apiForStreaming)
        let streamingInfoUseCase = StreamingInfoUseCase(streamingInfoRepository: streamingInfoRepository)
        let path = streamingInfoUseCase.streamingURL(for: node)
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
    
    @objc func seekToDestinationAndPlay(_ mediaDestination: MOMediaDestination?) {
        guard let fileUrl else { return }
        
        startLoading()
        let playerItem = AVPlayerItem(url: fileUrl)
        
        if let node {
            setPlayerItemMetadata(playerItem: playerItem, node: node)
        }
        
        seekTo(mediaDestination: mediaDestination, playerItem: playerItem)
        player = AVPlayer(playerItem: playerItem)
        subscriptions.add(bindPlayerItemStatus(playerItem: playerItem))
        
        setupVideoMetricsTracking()
        player?.play()
        subscriptions.add(bindPlayerTimeControlStatus())
        subscriptions.add(bindPlayerExternalPlayback())
    }
    
    @objc func beginAudioPlayerInterruptionIfNeeded() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.audioInterruptionDidStart()
        }
    }
    
    @objc func stopHttpServerAndResetAudioSession() {
        let capturedNode = self.node
        let capturedAPI = self.apiForStreaming
        Task {
            if capturedNode != nil, let api = capturedAPI {
                await DispatchQueue.global(qos: .userInitiated).asyncPerform {
                    api.httpServerStop()
                }
            }
            
            if !AudioPlayerManager.shared.isPlayerAlive() {
                await DispatchQueue.global(qos: .userInitiated).asyncPerform {
                    let audioSessionUseCase = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession.sharedInstance()))
                    audioSessionUseCase.configureDefaultAudioSession()
                }
            }
            
            if AudioPlayerManager.shared.isPlayerAlive() {
                AudioPlayerManager.shared.audioInterruptionDidEndNeedToResume(true)
            }
        }
    }
}

extension MEGAAVViewController {
    @objc func setupVideoMetricsTracking() {
        guard let player = player, let playerItem = player.currentItem else { return }
        metricsTracker = VideoMetricsTracker(
            player: player,
            playerItem: playerItem,
            tracker: DIContainer.tracker
        )
        metricsTracker?.startStartupTracking()
    }
    
    @objc func stopVideoMetricsTracking() {
        metricsTracker?.stopTracking()
    }
}
