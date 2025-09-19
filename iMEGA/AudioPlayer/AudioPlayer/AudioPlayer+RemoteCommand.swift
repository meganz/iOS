@preconcurrency import AVFoundation
import MediaPlayer
import MEGAAssets

extension AudioPlayer {
    func registerRemoteControls() {
        mediaPlayerRemoteCommandCenter.playCommand.addTarget(self, action: #selector(audioPlayer(didReceivePlayCommand:)))
        mediaPlayerRemoteCommandCenter.pauseCommand.addTarget(self, action: #selector(audioPlayer(didReceivePauseCommand:)))
        mediaPlayerRemoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(audioPlayer(didReceiveNextTrackCommand:)))
        mediaPlayerRemoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(audioPlayer(didReceivePreviousTrackCommand:)))
        mediaPlayerRemoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(audioPlayer(didReceiveTogglePlayPauseCommand:)))
        mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(audioPlayer(didReceiveChangePlaybackPositionCommand:)))
    }
    
    func unregisterRemoteControls() {
        mediaPlayerRemoteCommandCenter.playCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.pauseCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.nextTrackCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.previousTrackCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.seekForwardCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.seekBackwardCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand.removeTarget(self)
    }
    
    func refreshNowPlayingInfo() {
        updateNowPlayingInfo()
        updateCommandsState(enabled: true)
    }
    
    private func updateNowPlayingInfo() {
        guard let item = currentItem() else { return }
        let asset = item.asset
        let title = item.name
        let artist = item.artist ?? ""
        let elapsed = item.currentTime().seconds
        let artwork = mediaItemPropertyArtwork(item)
        let rate = NSNumber(value: isPaused ? 0.0 : 1.0)
        
        updateNowPlayingInfoTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let duration = try await asset.load(.duration)
                
                mediaPlayerNowPlayingInfoCenter.nowPlayingInfo = [
                    MPMediaItemPropertyPlaybackDuration: duration.seconds,
                    MPMediaItemPropertyTitle: title,
                    MPMediaItemPropertyArtist: artist,
                    MPNowPlayingInfoPropertyPlaybackRate: rate,
                    MPMediaItemPropertyArtwork: artwork,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed
                ]
            } catch {
                CrashlyticsLogger.log(
                    category: .audioPlayer,
                    "Failed to load duration for “\(title)”: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func mediaItemPropertyArtwork(_ item: AudioPlayerItem) -> MPMediaItemArtwork {
        if let artwork = item.artwork {
            return MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        } else {
            let defaultArtworkImage = MEGAAssets.UIImage.image(forFileName: item.name)
            return MPMediaItemArtwork(boundsSize: defaultArtworkImage.size) { _ in defaultArtworkImage }
        }
    }
}

// MARK: - Audio Player Remote Command Functions
extension AudioPlayer {
    @objc func audioPlayer(didReceivePlayCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event, requiresPlayableItem: true) { player in
            if player.queuePlayer?.rate == 0.0 { player.play() }
        }
    }
    
    @objc func audioPlayer(didReceivePauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event, requiresPlayableItem: true) { player in
            if player.queuePlayer?.rate == 1.0 { player.pause() }
        }
    }
    
    @objc func audioPlayer(didReceiveTogglePlayPauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event, requiresPlayableItem: true) { player in
            if player.queuePlayer?.rate == 0.0 { player.play() } else { player.pause() }
        }
    }
    
    @objc func audioPlayer(didReceiveNextTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { player in
            if player.isRepeatOneMode() {
                player.repeatAll(true)
                player.notify(player.aboutAudioPlayerConfiguration)
            }
            player.disableRemoteCommands()
            player.playNext { [weak player] in
                player?.enableRemoteCommands()
            }
        }
    }
    
    @objc func audioPlayer(didReceivePreviousTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { player in
            player.disableRemoteCommands()
            player.playPrevious { [weak player] in
                player?.enableRemoteCommands()
            }
        }
    }
    
    @objc func audioPlayer(didReceiveChangePlaybackPositionCommand event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event, requiresPlayableItem: true) { player in
            changePlaybackPositionCommandTask = Task { @MainActor in
                await player.setProgressCompleted(event.positionTime)
            }
        }
    }
    
    private func updateCommandsState(enabled: Bool) {
        mediaPlayerRemoteCommandCenter.playCommand.isEnabled = enabled
        mediaPlayerRemoteCommandCenter.pauseCommand.isEnabled = enabled
        mediaPlayerRemoteCommandCenter.nextTrackCommand.isEnabled = enabled
        mediaPlayerRemoteCommandCenter.previousTrackCommand.isEnabled = enabled
        mediaPlayerRemoteCommandCenter.togglePlayPauseCommand.isEnabled = enabled
        mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand.isEnabled = enabled
        
        if enabled {
            registerRemoteControls()
        } else {
            unregisterRemoteControls()
        }
    }
    
    func enableRemoteCommands() {
        updateCommandsState(enabled: true)
        refreshNowPlayingInfo()
    }
    
    func disableRemoteCommands() {
        updateCommandsState(enabled: false)
    }
    
    /// Centralized preflight for all remote commands. Returns a non-nil status if the command should not proceed.
    func remoteCommandPreflight(
        _ event: MPRemoteCommandEvent,
        requiresPlayableItem: Bool
    ) -> MPRemoteCommandHandlerStatus? {
        guard event.command.isEnabled, !hasTornDown, !isAudioPlayerInterrupted else { return .commandFailed }
        
        if requiresPlayableItem, currentItem() == nil {
            return queuePlayer == nil ? .noSuchContent : .noActionableNowPlayingItem
        }
        
        return nil
    }
    
    /// Unified execution path: perform preflight checks, run the action, return status. `.success` means the command was accepted and the operation was **initiated**.
    func performRemoteCommand(
        _ event: MPRemoteCommandEvent,
        requiresPlayableItem: Bool = false,
        _ action: (AudioPlayer) -> Void
    ) -> MPRemoteCommandHandlerStatus {
        if let status = remoteCommandPreflight(event, requiresPlayableItem: requiresPlayableItem) {
            return status
        }
        action(self)
        return .success
    }
}
