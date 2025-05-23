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
        
        Task { @MainActor in
            guard let duration = try? await item.asset.load(.duration) else { return }
            
            mediaPlayerNowPlayingInfoCenter.nowPlayingInfo = [
                MPMediaItemPropertyPlaybackDuration: duration.seconds,
                MPMediaItemPropertyTitle: item.name,
                MPMediaItemPropertyArtist: item.artist ?? "",
                MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: isPaused ? 0.0 : 1.0),
                MPMediaItemPropertyArtwork: mediaItemPropertyArtwork(item),
                MPNowPlayingInfoPropertyElapsedPlaybackTime: item.currentTime().seconds
            ]
        }
    }
    
    private func mediaItemPropertyArtwork(_ item: AudioPlayerItem) -> MPMediaItemArtwork {
        if let artwork = item.artwork {
            return MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        } else {
            let defaultArtworkImage = MEGAAssets.UIImage.defaultArtwork
            return MPMediaItemArtwork(boundsSize: defaultArtworkImage.size) { _ in defaultArtworkImage }
        }
    }
}

// MARK: - Audio Player Remote Command Functions
extension AudioPlayer {
    @objc func audioPlayer(didReceivePlayCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, let player = queuePlayer, !isAudioPlayerInterrupted else { return .commandFailed }
        if player.rate == 0.0 {
            play()
            return .success
        }

        return .commandFailed
    }
    
    @objc func audioPlayer(didReceivePauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, let player = queuePlayer, !isAudioPlayerInterrupted else { return .commandFailed }
        
        if player.rate == 1.0 {
            pause()
            return .success
        }

        return.commandFailed
    }
    
    @objc func audioPlayer(didReceiveNextTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, queuePlayer != nil, !isAudioPlayerInterrupted else { return .commandFailed }
        
        if isRepeatOneMode() {
            repeatAll(true)
            notify(aboutAudioPlayerConfiguration)
        }
        
        disableRemoteCommands()
        playNext { [weak self] in
            guard let `self` = self else { return }
            self.enableRemoteCommands()
        }

        return.success
    }
    
    @objc func audioPlayer(didReceivePreviousTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, queuePlayer != nil, !isAudioPlayerInterrupted else { return .commandFailed }
        
        disableRemoteCommands()
        playPrevious { [weak self] in
            guard let `self` = self else { return }
            self.enableRemoteCommands()
        }

        return.success
    }
    
    @objc func audioPlayer(didReceiveTogglePlayPauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, let player = queuePlayer, !isAudioPlayerInterrupted else { return .commandFailed }
        
        if isPlaying {
            if player.rate == 1.0 {
                pause()
                return .success
            }
        } else {
            if player.rate == 0.0 {
                play()
                return .success
            }
        }

        return.commandFailed
    }
    
    @objc func audioPlayer(didReceiveChangePlaybackPositionCommand event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled, !isAudioPlayerInterrupted else { return .commandFailed }
        setProgressCompleted(event.positionTime)
        return .success
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
}
