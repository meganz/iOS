import Foundation

extension AudioPlayer {
    func registerAudioPlayerEvents() {
        eventCancellables.removeAll()
        
        queuePlayer
            .publisher(for: \.currentItem, options: [.old, .new])
            .scan((previousItem: AVPlayerItem?.none, currentItem: AVPlayerItem?.none)) { last, newItem in
                (previousItem: last.currentItem, currentItem: newItem)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] itemChange in
                guard let self, !self.hasTornDown else { return }
                didChangeCurrentItem(
                    previousItem: itemChange.previousItem,
                    currentItem: itemChange.currentItem
                )
            }
            .store(in: &eventCancellables)
        
        queuePlayer.currentItem?
            .publisher(for: \.status, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] itemStatus in
                guard let self, !self.hasTornDown else { return }
                didChangeCurrentItemStatus(status: itemStatus)
            }
            .store(in: &eventCancellables)
        
        queuePlayer
            .publisher(for: \.currentItem, options: .initial)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newItem in
                guard let self, !self.hasTornDown else { return }
                didStartPlayingCurrentItem(newItem)
            }
            .store(in: &eventCancellables)
        
        queuePlayer
            .publisher(for: \.rate, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRate in
                guard let self, !self.hasTornDown else { return }
                didChangePlayerRate(newRate)
            }
            .store(in: &eventCancellables)
        
        queuePlayer
            .publisher(for: \.timeControlStatus, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTimeControlStatus in
                guard let self, !self.hasTornDown else { return }
                didChangeTimeControlStatus(newTimeControlStatus)
            }
            .store(in: &eventCancellables)
        
        queuePlayer
            .publisher(for: \.reasonForWaitingToPlay, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newReason in
                guard let self, !self.hasTornDown else { return }
                didChangeReasonForWaitingToPlay(newReason)
            }
            .store(in: &eventCancellables)
        
        queuePlayer.currentItem?
            .publisher(for: \.isPlaybackBufferEmpty, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bufferStatus in
                guard let self, !self.hasTornDown else { return }
                isPlaybackBufferEmpty(bufferStatus)
            }
            .store(in: &eventCancellables)
        
        queuePlayer.currentItem?
            .publisher(for: \.isPlaybackLikelyToKeepUp, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bufferStatus in
                guard let self, !self.hasTornDown else { return }
                isPlaybackLikelyToKeepUp(bufferStatus)
            }
            .store(in: &eventCancellables)
        
        queuePlayer.currentItem?
            .publisher(for: \.isPlaybackBufferFull, options: .new)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bufferStatus in
                guard let self, !self.hasTornDown else { return }
                isPlaybackBufferFull(bufferStatus)
            }
            .store(in: &eventCancellables)
        
        queuePlayer.publisher(for: \.currentItem, options: [.initial, .new])
            .compactMap { $0 }
            .flatMap { item in
                item
                    .publisher(for: \.loadedTimeRanges, options: .new)
                    .map { (item: item, loadedTimeRanges: $0) }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self, !self.hasTornDown else { return }
                self.didLoadTimeRanges(
                    for: event.item,
                    ranges: event.loadedTimeRanges
                )
            }
            .store(in: &eventCancellables)
    }
    
    func unregisterAudioPlayerEvents() {
        eventCancellables.removeAll()
        removeTimeObserver()
    }
    
    func registerAudioPlayerNotifications() {
        notificationCancellables.removeAll()
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, !self.hasTornDown else { return }
                self.handleInterruption(notification: notification)
            }
            .store(in: &notificationCancellables)
        
        notificationCenter.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, !self.hasTornDown else { return }
                self.handleRouteChange(notification: notification)
            }
            .store(in: &notificationCancellables)
        
        notificationCenter.publisher(for: .MEGAAudioPlayerInterruption)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, !self.hasTornDown else { return }
                self.handleInterruption(notification: notification)
            }
            .store(in: &notificationCancellables)
        
        notificationCenter.publisher(for: .MEGATransferOverQuota)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, !self.hasTornDown else { return }
                self.handleTransferQuotaExceeded(notification: notification)
            }
            .store(in: &notificationCancellables)
    }
    
    func unregisterAudioPlayerNotifications() {
        notificationCancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateLoadingView(isLoading: Bool) {
        if isLoading {
            notify(aboutShowingLoadingView)
        } else {
            notify(aboutHidingLoadingView)
        }
    }
}

// MARK: - Audio Player Observed Events Functions
extension AudioPlayer {
    private func didChangeCurrentItem(previousItem: AVPlayerItem?, currentItem: AVPlayerItem?) {
        // Audio player media item changed...
        notify(aboutTheEndOfBlockingAction)
        
        if let repeatOneAllowed = audioPlayerConfig[.repeatOne] as? Bool, repeatOneAllowed {
            repeatLastItem()
        } else {
            notify([aboutCurrentItem, aboutCurrentItemAndQueue, aboutCurrentThumbnail, aboutUpdateCurrentIndexPath])
            guard let previous = previousItem as? AudioPlayerItem else {
                return
            }
            
            previouslyPlayedItem = previous
            reset(item: previous)
            
            updateQueueWithLoopItems()
            
            resetPlayerItems()
        }
        
        reloadCurrentThumbnail()
        
        onItemFinishedPlaying()
    }
    
    private func reloadCurrentThumbnail() {
        Task { @MainActor in
            await loadACurrentItemArtworkIfNeeded()
            notify([aboutCurrentThumbnail])
            refreshNowPlayingInfo()
        }
    }
    
    /// Listening for changes in the current item's status
    /// (e.g., .unknown → .readyToPlay or .failed). We update metadata and, if the player was in the middle of a forced reset, resume playback.
    private func didChangeCurrentItemStatus(status: AVPlayerItem.Status?) {
        refreshNowPlayingInfo()
        
        if isAudioPlayerBeingReset {
            if resettingPlayback {
                play()
                resettingPlayback = false
            }
            isAudioPlayerBeingReset = false
        }
        
        if status == .readyToPlay {
            updateLoadingView(isLoading: false)
        }
        
        if queuePlayer.status == .readyToPlay, !hasCompletedInitialConfiguration {
            hasCompletedInitialConfiguration = true
        }
    }
    
    // Listening for event about the status of the playback
    func didChangeTimeControlStatus(_ timeControlStatus: AVPlayer.TimeControlStatus) {
        switch timeControlStatus {
        case .paused:
            isPaused = true
            notify([aboutCurrentItem, aboutCurrentState, aboutCurrentThumbnail])
            
            if let currentItem = queuePlayer.currentItem as? AudioPlayerItem {
                // Check if the new item is the same as the previously played item
                isUserPreviouslyJustPlayedSameItem = (currentItem == previouslyPlayedItem)
            }
            
        case .waitingToPlayAtSpecifiedRate:
            /// Only show the loading indicator when AVPlayer is buffering
            /// (i.e. waiting “to minimize stalls”), to avoid spinners for other wait reasons
            if queuePlayer.reasonForWaitingToPlay == .toMinimizeStalls || queuePlayer.reasonForWaitingToPlay == .evaluatingBufferingRate {
                updateLoadingView(isLoading: true)
            }
            
        case .playing:
            isPaused = false
            notify([aboutCurrentItem, aboutCurrentState, aboutCurrentThumbnail, aboutHidingLoadingView])
            
            if let currentItem = queuePlayer.currentItem as? AudioPlayerItem {
                // Check if the new item is the same as the previously played item
                isUserPreviouslyJustPlayedSameItem = (currentItem == previouslyPlayedItem)
                
                previouslyPlayedItem = currentItem
            }
            
        default:
            break
        }
    }
    
    /// Listening for reasons the player is unable to start immediately
    /// (e.g., buffering, ad interstitials, SharePlay sync). Here we only update the Now Playing metadata
    func didChangeReasonForWaitingToPlay(_ newReason: AVQueuePlayer.WaitingReason?) {
        refreshNowPlayingInfo()
    }
    
    func didStartPlayingCurrentItem(_ currentItem: AVPlayerItem?) {
        refreshNowPlayingInfo()
        
        let isRepeatAllEnabled = audioPlayerConfig[.loop] as? Bool ?? false
        let isRepeatOneEnabled = audioPlayerConfig[.repeatOne] as? Bool ?? false
        let hasReachedEndOfPlaylist = queuePlayer.items().count == 1
        
        if hasReachedEndOfPlaylist && !isRepeatOneEnabled && !isRepeatAllEnabled {
            resettingPlayback = true
        }
        
        /// If the playlist is not finished or a repeat mode is active, notify that a new item is starting. This means that if there are still items to play, or if repeat-all or repeat-one is enabled,
        /// the system should update the now playing status. If there is no repeat mode active, and we have reached the end of the playlist, we want to reset the playlist to the first track
        /// of the playlist, and pause the audio player playback.
        if !hasReachedEndOfPlaylist || isRepeatAllEnabled || isRepeatOneEnabled {
            notify(aboutStartPlayingNewItem)
        }
    }
    
    func didChangePlayerRate(_ rate: Float) {
        refreshNowPlayingInfo()
    }
    
    private func didLoadTimeRanges(for item: AVPlayerItem, ranges: [NSValue]) {
        guard item.status == .readyToPlay else {
            CrashlyticsLogger.log(category: .audioPlayer, "Player status is \(item.status) – waiting for .readyToPlay.")
            return
        }
        
        guard let timeRanges = ranges as? [CMTimeRange],
              timeRanges.isNotEmpty,
              let firstTimeRange = timeRanges.first else {
            CrashlyticsLogger.log(category: .audioPlayer, "Observed change has no newValue or the ranges array is empty \(String(describing: ranges))")
            return
        }
        let duration = firstTimeRange.duration.value
        let timescale = firstTimeRange.duration.timescale
        
        guard duration > 0, timescale > 0 else {
            CrashlyticsLogger.log(category: .audioPlayer, "Invalid duration. value=\(duration), timescale=\(timescale).")
            return
        }
        
        let timeLoaded = Int(duration) / Int(timescale)

        if timeLoaded > 0 {
            notify([aboutCurrentState, aboutCurrentItem])
        }
    }
    
    /// Called when the playback buffer has emptied out (no more data to play).
    /// Wraps up the current item and enters buffering state.
    func isPlaybackBufferEmpty(_ isBufferEmpty: Bool?) {
        guard isBufferEmpty == true else { return }
        updateLoadingView(isLoading: true)
        onItemFinishedPlaying()
    }

    /// Called when the buffer has refilled enough to resume smooth playback.
    /// Exits buffering state so UI and timers can restart.
    func isPlaybackLikelyToKeepUp(_ isBufferLikelyToKeepUp: Bool?) {
        guard isBufferLikelyToKeepUp == true else { return }
        updateLoadingView(isLoading: false)
        notify(aboutAudioPlayerDidFinishBuffering)
    }

    /// Called when the buffer is completely full (all chunks loaded).
    /// Hides any loading indicators now that playback won’t stall.
    func isPlaybackBufferFull(_ isBufferFull: Bool?) {
        guard isBufferFull == true else { return }
        updateLoadingView(isLoading: false)
    }
    
    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            guard !isAudioPlayerInterrupted else { return }
            
            if let isAudioSessionSuspended = userInfo[AVAudioSessionInterruptionReasonKey] as? Bool, isAudioSessionSuspended {
                MEGALogDebug("[AudioPlayer] The Audio Session was deactivated by the system")
                return
            }
            
            MEGALogDebug("[AudioPlayer] AVAudioSessionInterruptionBegan")
            
            setAudioPlayer(interrupted: true, needToBeResumed: !isPaused)
            
            if !isPaused {
                pause()
            }
            
        case .ended:
            guard isAudioPlayerInterrupted, let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            
            MEGALogDebug("[AudioPlayer] AVAudioSessionInterruptionEnded")
            
            if AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) && needToBeResumedAfterInterruption {
                resetAudioSessionCategoryIfNeeded()
                play()
            }
            setAudioPlayer(interrupted: false, needToBeResumed: false)
        default: break
        }
        
        notify(aboutCurrentState)
    }
    
    private func handleRouteChange(notification: Notification) {
        guard !isAudioPlayerInterrupted,
              let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let type = AVAudioSession.RouteChangeReason(rawValue: typeValue) else { return }
        
        switch type {
        case .oldDeviceUnavailable:
            MEGALogDebug("[AudioPlayer] AVAudioSessionRouteChangeReason OldDeviceunavailable")
            if !isAudioPlayerInterrupted { pause() }
            
        default:
            break
        }
        
        notify(aboutCurrentState)
    }
    
    private func handleTransferQuotaExceeded(notification: Notification) {
        if !isPaused { pause() }
        
        preloadMetadataTask?.cancel()
        
        notify(aboutCurrentState)
    }
}
