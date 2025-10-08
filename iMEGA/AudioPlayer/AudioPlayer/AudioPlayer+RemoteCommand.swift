@preconcurrency import AVFoundation
import MediaPlayer
import MEGAAssets

extension AudioPlayer {
    private var managedRemoteCommands: [MPRemoteCommand] {
        [
            mediaPlayerRemoteCommandCenter.playCommand,
            mediaPlayerRemoteCommandCenter.pauseCommand,
            mediaPlayerRemoteCommandCenter.togglePlayPauseCommand,
            mediaPlayerRemoteCommandCenter.nextTrackCommand,
            mediaPlayerRemoteCommandCenter.previousTrackCommand,
            mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand
        ]
    }
    
    func registerRemoteControls() {
        mediaPlayerRemoteCommandCenter.playCommand.addTarget(self, action: #selector(audioPlayer(didReceivePlayCommand:)))
        mediaPlayerRemoteCommandCenter.pauseCommand.addTarget(self, action: #selector(audioPlayer(didReceivePauseCommand:)))
        mediaPlayerRemoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(audioPlayer(didReceiveNextTrackCommand:)))
        mediaPlayerRemoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(audioPlayer(didReceivePreviousTrackCommand:)))
        mediaPlayerRemoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(audioPlayer(didReceiveTogglePlayPauseCommand:)))
        mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(audioPlayer(didReceiveChangePlaybackPositionCommand:)))
        
        updateRemoteCommandAvailability()
    }
    
    func unregisterRemoteControls() {
        mediaPlayerRemoteCommandCenter.playCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.pauseCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.nextTrackCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.previousTrackCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.togglePlayPauseCommand.removeTarget(self)
        mediaPlayerRemoteCommandCenter.changePlaybackPositionCommand.removeTarget(self)
    }
    
    /// Updates the enabled state of all remote commands based on player availability.
    /// Remote commands are enabled only when the player is active and not interrupted. This method delegates the actual state handling to `setRemoteCommandsEnabled(_:)`,
    /// which ensures redundant updates are avoided.
    func updateRemoteCommandAvailability() {
        setRemoteCommandsEnabled(!(hasTornDown || isAudioPlayerInterrupted))
    }
    
    func enableRemoteCommands() {
        setRemoteCommandsEnabled(true)
        refreshNowPlayingInfo()
    }
    
    func disableRemoteCommands() {
        setRemoteCommandsEnabled(false)
    }
    
    /// Enables or disables all remote commands, taking into account the player's state.
    /// This function automatically prevents enabling commands when the player is unavailable, either because it has been torn down (The AudioPlayer has been torn down and its resources released)
    /// or is currently interrupted (Possible reasons: a call or meeting in progress, music playing in another app, etc.).
    /// When unavailable, all remote commands are explicitly disabled to avoid user interactions from the system media controls. Otherwise, commands are set to
    /// the desired enabled state only when necessary, minimizing redundant updates.
    func setRemoteCommandsEnabled(_ shouldEnable: Bool) {
        guard !hasTornDown, !isAudioPlayerInterrupted else {
            managedRemoteCommands.forEach { $0.isEnabled = false }
            return
        }
        
        managedRemoteCommands.forEach { $0.isEnabled = shouldEnable }
    }
    
    func refreshNowPlayingInfo() {
        updateNowPlayingInfo()
        setRemoteCommandsEnabled(true)
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
    @objc nonisolated func audioPlayer(didReceivePlayCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self] in
            if self?.queuePlayer.rate == 0.0 { self?.play() }
        }
    }
    
    @objc nonisolated func audioPlayer(didReceivePauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self] in
            if self?.queuePlayer.rate == 1.0 { self?.pause() }
        }
    }
    
    @objc nonisolated func audioPlayer(didReceiveTogglePlayPauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self] in
            if self?.queuePlayer.rate == 0.0 { self?.play() } else { self?.pause() }
        }
    }
    
    @objc nonisolated func audioPlayer(didReceiveNextTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self, aboutAudioPlayerConfiguration] in
            if self?.isRepeatOneMode() == true {
                self?.repeatAll(true)
                self?.notify(aboutAudioPlayerConfiguration)
            }
            self?.setRemoteCommandsEnabled(false)
            self?.playNext {
                self?.setRemoteCommandsEnabled(true)
            }
        }
    }
    
    @objc nonisolated func audioPlayer(didReceivePreviousTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self] in
            self?.setRemoteCommandsEnabled(false)
            self?.playPrevious {
                self?.setRemoteCommandsEnabled(true)
            }
        }
    }
    
    @objc nonisolated func audioPlayer(didReceiveChangePlaybackPositionCommand event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        performRemoteCommand(event) { [weak self] in
            self?.changePlaybackPositionCommandTask = Task { @MainActor in
                await self?.setProgressCompleted(event.positionTime)
            }
        }
    }
    
    /// Executes a remote command action on the main actor and returns its status.
    /// Returns `.success` when the command is enabled and its action is scheduled for execution.
    /// Returns `.commandFailed` only if the command is disabled, ensuring that no work is performed when the command is not actionable.
    /// Remote commands are dynamically enabled or disabled through `updateRemoteCommandAvailability()`, so this function can safely assume that
    /// actionable commands are valid by the time they reach this point.
    nonisolated private func performRemoteCommand(
        _ event: MPRemoteCommandEvent,
        _ action: @escaping @MainActor () -> Void
    ) -> MPRemoteCommandHandlerStatus {
        guard event.command.isEnabled else { return .commandFailed }
        
        Task { @MainActor [weak self] in
            if self?.currentItem() != nil {
                action()
            }
        }
        return .success
    }
}
