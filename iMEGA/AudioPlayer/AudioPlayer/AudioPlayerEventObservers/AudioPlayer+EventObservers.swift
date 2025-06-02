import Foundation

extension AudioPlayer {
    func registerAudioPlayerEvents() {
        audioQueueObserver = queuePlayer?.observe(\.currentItem, options: [.new, .old], changeHandler: audio(player:didChangeItem:))
        audioQueueStatusObserver = queuePlayer?.currentItem?.observe(\.status, options: [.new, .old], changeHandler: audio(playerItem:didChangeCurrentItemStatus:))
        audioQueueNewItemObserver = queuePlayer?.observe(\.currentItem, options: .initial, changeHandler: audio(player:didStartPlayingCurrentItem:))
        audioQueueRateObserver = queuePlayer?.observe(\.rate, options: .new, changeHandler: audio(player:didChangePlayerRate:))
        audioQueueStallObserver = queuePlayer?.observe(\.timeControlStatus, options: .new, changeHandler: audio(player:didChangeTimeControlStatus:))
        audioQueueWaitingObserver = queuePlayer?.observe(\.reasonForWaitingToPlay, options: [.new, .old], changeHandler: audio(player:reasonForWaitingToPlay:))
        audioQueueBufferEmptyObserver = queuePlayer?.currentItem?.observe(\.isPlaybackBufferEmpty, options: [.new], changeHandler: audio(playerItem:isPlaybackBufferEmpty:))
        audioQueueBufferAlmostThereObserver = queuePlayer?.currentItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new], changeHandler: audio(playerItem:isPlaybackBufferLikelyToKeepUp:))
        audioQueueBufferFullObserver = queuePlayer?.currentItem?.observe(\.isPlaybackBufferFull, options: [.new], changeHandler: audio(playerItem:isPlaybackBufferFull:))
        audioQueueLoadedTimeRangesObserver = queuePlayer?.currentItem?.observe(\.loadedTimeRanges, options: .new, changeHandler: audio(playerItem:didLoadedTimeRanges:))
    }
    
    func unregisterAudioPlayerEvents() {
        audioQueueObserver?.invalidate()
        audioQueueStatusObserver?.invalidate()
        audioQueueNewItemObserver?.invalidate()
        audioQueueRateObserver?.invalidate()
        audioQueueWaitingObserver?.invalidate()
        audioQueueStallObserver?.invalidate()
        audioQueueBufferEmptyObserver?.invalidate()
        audioQueueBufferAlmostThereObserver?.invalidate()
        audioQueueBufferFullObserver?.invalidate()
        audioQueueLoadedTimeRangesObserver?.invalidate()
        audioSeekFallbackObserver?.invalidate()
        
        audioQueueObserver = nil
        audioQueueStatusObserver = nil
        audioQueueNewItemObserver = nil
        audioQueueRateObserver = nil
        audioQueueWaitingObserver = nil
        audioQueueStallObserver = nil
        audioQueueBufferEmptyObserver = nil
        audioQueueBufferAlmostThereObserver = nil
        audioQueueBufferFullObserver = nil
        audioQueueLoadedTimeRangesObserver = nil
        audioSeekFallbackObserver = nil
    }
    
    func registerAudioPlayerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayer(interruption:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayer(changeRoute:)), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayer(interruption:)), name: .MEGAAudioPlayerInterruption, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTransferQuotaExceededNotification(_:)), name: .MEGATransferOverQuota, object: nil)
    }
    
    func unregisterAudioPlayerNotifications() {
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
    // Listening for current item change
    func audio(player: AVQueuePlayer, didChangeItem change: NSKeyValueObservedChange<AVPlayerItem?>) {
        // Audio player media item changed...
        notify(aboutTheEndOfBlockingAction)

        if let repeatOneAllowed = audioPlayerConfig[.repeatOne] as? Bool, repeatOneAllowed {
            repeatLastItem()
        } else {
            notify([aboutCurrentItem, aboutCurrentItemAndQueue, aboutCurrentThumbnail, aboutUpdateCurrentIndexPath])
            guard let oldValue = change.oldValue as? AudioPlayerItem else {
                return
            }
            
            previouslyPlayedItem = oldValue
            reset(item: oldValue)
            
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
    
    // Listening for event about the status of the playback
    func audio(player: AVQueuePlayer, didChangeTimeControlStatus change: NSKeyValueObservedChange<AVQueuePlayer.TimeControlStatus>) {
        switch player.timeControlStatus {
        case .paused:
            isPaused = true
            invalidateTimer()
            notify([aboutCurrentItem, aboutCurrentState, aboutCurrentThumbnail])
            
            if !isAutoPlayEnabled {
                updateLoadingView(isLoading: false)
            }
            
            if let currentItem = player.currentItem as? AudioPlayerItem {
                // Check if the new item is the same as the previously played item
                isUserPreviouslyJustPlayedSameItem = (currentItem == previouslyPlayedItem)
            }
            
        case .waitingToPlayAtSpecifiedRate:
            invalidateTimer()
            
            /// Only show the loading indicator when AVPlayer is buffering
            /// (i.e. waiting “to minimize stalls”), to avoid spinners for other wait reasons
            if player.reasonForWaitingToPlay == .toMinimizeStalls || player.reasonForWaitingToPlay == .evaluatingBufferingRate {
                updateLoadingView(isLoading: true)
            }
            
        case .playing:
            isPaused = false
            setTimer()
            notify([aboutCurrentItem, aboutCurrentState, aboutCurrentThumbnail, aboutHidingLoadingView])
            
            if let currentItem = player.currentItem as? AudioPlayerItem {
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
    func audio(player: AVQueuePlayer, reasonForWaitingToPlay change: NSKeyValueObservedChange<AVQueuePlayer.WaitingReason?>) {
        refreshNowPlayingInfo()
    }
    
    /// Listening for changes in the current item's status
    /// (e.g., .unknown → .readyToPlay or .failed). We update metadata and, if the player was in the middle of a forced reset, resume playback.
    func audio(playerItem: AVPlayerItem, didChangeCurrentItemStatus change: NSKeyValueObservedChange<AVPlayerItem.Status>) {
        refreshNowPlayingInfo()
        
        if isAudioPlayerBeingReset {
            if resettingPlayback {
                play()
                resettingPlayback = false
            }
            isAudioPlayerBeingReset = false
        }
        
        if change.newValue == .readyToPlay {
            updateLoadingView(isLoading: false)
        }
    }
    
    func audio(player: AVQueuePlayer, didStartPlayingCurrentItem change: NSKeyValueObservedChange<AVPlayerItem?>) {
        refreshNowPlayingInfo()
        
        let isRepeatAllEnabled = audioPlayerConfig[.loop] as? Bool ?? false
        let isRepeatOneEnabled = audioPlayerConfig[.repeatOne] as? Bool ?? false
        let hasReachedEndOfPlaylist = player.items().count == 1
        
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
    
    func audio(player: AVQueuePlayer, didChangePlayerRate change: NSKeyValueObservedChange<Float>) {
        refreshNowPlayingInfo()
    }
    
    func audio(playerItem: AVPlayerItem, didLoadedTimeRanges change: NSKeyValueObservedChange<[NSValue]>) {
        guard playerItem.status == .readyToPlay else {
            CrashlyticsLogger.log(category: .audioPlayer, "Player status is \(playerItem.status) – waiting for .readyToPlay.")
            return
        }
        
        guard let newValue = change.newValue,
              let timeRanges = newValue as? [CMTimeRange],
              timeRanges.isNotEmpty,
              let firstTimeRange = timeRanges.first else {
            CrashlyticsLogger.log(category: .audioPlayer, "Observed change has no newValue or the ranges array is empty \(String(describing: change.newValue))")
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
    func audio(playerItem: AVPlayerItem, isPlaybackBufferEmpty change: NSKeyValueObservedChange<Bool>) {
        guard change.newValue == true else { return }
        updateLoadingView(isLoading: true)
        onItemFinishedPlaying()
    }

    /// Called when the buffer has refilled enough to resume smooth playback.
    /// Exits buffering state so UI and timers can restart.
    func audio(playerItem: AVPlayerItem, isPlaybackBufferLikelyToKeepUp change: NSKeyValueObservedChange<Bool>) {
        guard change.newValue == true else { return }
        updateLoadingView(isLoading: false)
        notify(aboutAudioPlayerDidFinishBuffering)
    }

    /// Called when the buffer is completely full (all chunks loaded).
    /// Hides any loading indicators now that playback won’t stall.
    func audio(playerItem: AVPlayerItem, isPlaybackBufferFull change: NSKeyValueObservedChange<Bool>) {
        guard change.newValue == true else { return }
        updateLoadingView(isLoading: false)
    }

    @objc func audioPlayer(interruption notification: Notification) {
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
                disableRemoteCommands()
                pause()
            }
            
        case .ended:
            guard isAudioPlayerInterrupted, let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            
            MEGALogDebug("[AudioPlayer] AVAudioSessionInterruptionEnded")
            
            enableRemoteCommands()
            
            if AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) && needToBeResumedAfterInterruption {
                resetAudioSessionCategoryIfNeeded()
                play()
            }
            setAudioPlayer(interrupted: false, needToBeResumed: false)
        default: break
        }
        
        notify(aboutCurrentState)
    }
    
    @objc func audioPlayer(changeRoute notification: Notification) {
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
    
    @objc func handleTransferQuotaExceededNotification(_ notification: Notification) {
        if !isPaused { pause() }
        
        preloadMetadataTask?.cancel()
        
        notify(aboutCurrentState)
    }
}
