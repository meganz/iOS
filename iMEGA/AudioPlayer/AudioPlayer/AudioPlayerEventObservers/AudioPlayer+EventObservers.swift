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
}

// MARK: - Audio Player Observed Events Functions
extension AudioPlayer {
    // Listening for current item change
    func audio(player: AVQueuePlayer, didChangeItem value: NSKeyValueObservedChange<AVPlayerItem?>) {
        // Audio player media item changed...
        notify(aboutTheEndOfBlockingAction)

        if let repeatOneAllowed = audioPlayerConfig[.repeatOne] as? Bool, repeatOneAllowed {
            repeatLastItem()
        } else {
            notify([aboutCurrentItem, aboutCurrentItemAndQueue, aboutCurrentThumbnail, aboutUpdateCurrentIndexPath])
            guard let oldValue = value.oldValue as? AudioPlayerItem else {
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
    func audio(player: AVQueuePlayer, didChangeTimeControlStatus value: NSKeyValueObservedChange<AVQueuePlayer.TimeControlStatus>) {
        switch player.timeControlStatus {
        case .paused:
            isPaused = true
            invalidateTimer()
            notify([aboutCurrentItem, aboutCurrentState, aboutCurrentThumbnail, aboutHidingLoadingView])
            
            if let currentItem = player.currentItem as? AudioPlayerItem {
                // Check if the new item is the same as the previously played item
                isUserPreviouslyJustPlayedSameItem = (currentItem == previouslyPlayedItem)
            }
            
        case .waitingToPlayAtSpecifiedRate:
            invalidateTimer()
            notify(aboutShowingLoadingView)
            
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

    // listening for change event when player stops playback
    func audio(player: AVQueuePlayer, reasonForWaitingToPlay value: NSKeyValueObservedChange<AVQueuePlayer.WaitingReason?>) {
        // To know the reason for waiting to play you can see it with: player.reasonForWaitingToPlay?.rawValue
        
        let controller = AudioPlayerEventObserversLoadingLogicController()
        let shouldNotifyLoadingView = controller.shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
            reasonForWaitingToPlay: player.reasonForWaitingToPlay,
            playerStatus: player.status,
            playerTimeControlStatus: player.timeControlStatus,
            isUserPreviouslyJustPlayedSameItem: isUserPreviouslyJustPlayedSameItem
        )
        shouldNotifyLoadingView ? notify(aboutShowingLoadingView) : notify(aboutHidingLoadingView)
        
        refreshNowPlayingInfo()
    }
    
    // Listening for current item status change
    func audio(playerItem: AVPlayerItem, didChangeCurrentItemStatus value: NSKeyValueObservedChange<AVPlayerItem.Status>) {
        let controller = AudioPlayerEventObserversLoadingLogicController()
        if let shouldNotifyLoadingView = controller.shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: playerItem.status) {
            shouldNotifyLoadingView ? notify(aboutShowingLoadingView) : notify(aboutHidingLoadingView)
        }
        
        refreshNowPlayingInfo()
        
        if isAudioPlayerBeingReset {
            if resettingPlayback {
                play()
                resettingPlayback = false
            }
            isAudioPlayerBeingReset = false
        }
    }
    
    func audio(player: AVQueuePlayer, didStartPlayingCurrentItem value: NSKeyValueObservedChange<AVPlayerItem?>) {
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
    
    func audio(player: AVQueuePlayer, didChangePlayerRate value: NSKeyValueObservedChange<Float>) {
        refreshNowPlayingInfo()
        if value.newValue ?? 0.0 > 0 {
            notify(aboutHidingLoadingView)
        }
    }
    
    func audio(playerItem: AVPlayerItem, didLoadedTimeRanges value: NSKeyValueObservedChange<[NSValue]>) {
        guard
            let timeRanges = value.newValue as? [CMTimeRange],
            let duration = timeRanges.first?.duration else {
            return
        }
                
        let timeLoaded = Int(duration.value) / Int(duration.timescale)

        if playerItem.status == .readyToPlay && timeLoaded > 0 {
            notify([aboutCurrentState, aboutCurrentItem])
        }
    }
    
    /// Called when the playback buffer has emptied out (no more data to play).
    /// Wraps up the current item and enters buffering state.
    func audio(playerItem: AVPlayerItem, isPlaybackBufferEmpty value: NSKeyValueObservedChange<Bool>) {
        guard value.newValue == true else { return }
        onItemFinishedPlaying()
    }

    /// Called when the buffer has refilled enough to resume smooth playback.
    /// Exits buffering state so UI and timers can restart.
    func audio(playerItem: AVPlayerItem, isPlaybackBufferLikelyToKeepUp value: NSKeyValueObservedChange<Bool>) {
        guard value.newValue == true else { return }
        notify(aboutAudioPlayerDidFinishBuffering)
    }

    /// Called when the buffer is completely full (all chunks loaded).
    /// Hides any loading indicators now that playback won’t stall.
    func audio(playerItem: AVPlayerItem, isPlaybackBufferFull value: NSKeyValueObservedChange<Bool>) {
        guard value.newValue == true else { return }
        notify(aboutHidingLoadingView)
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
