import AVFoundation
import MEGADomain
import MessageKit
import UIKit

/// The `PlayerState` indicates the current audio controller state
public enum PlayerState {

    /// The audio controller is currently playing a sound
    case playing

    /// The audio controller is currently in pause state
    case pause

    /// The audio controller is not playing any sound and audioPlayer is nil
    case stopped
}

/// The `BasicAudioController` update UI for current audio cell that is playing a sound
/// and also creates and manage an `AVAudioPlayer` states, play, pause and stop.
open class BasicAudioController: NSObject, AVAudioPlayerDelegate {

    /// The `AVAudioPlayer` that is playing the sound
    open var audioPlayer: AVAudioPlayer?

    /// The `AudioMessageCell` that is currently playing sound
    open weak var playingCell: AudioMessageCell?

    /// The `MessageType` that is currently playing sound
    open var playingMessage: (any MessageType)?

    /// Specify if current audio controller state: playing, in pause or none
    open private(set) var state: PlayerState = .stopped

    // The `MessagesCollectionView` where the playing cell exist
    public weak var messageCollectionView: MessagesCollectionView?

    /// The `Timer` that update playing progress
    internal var progressTimer: Timer?

    // MARK: - Init Methods

    public init(messageCollectionView: MessagesCollectionView) {
        self.messageCollectionView = messageCollectionView
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAudioRoute), name: AVAudioSession.routeChangeNotification, object: nil)

    }
    
    func setProximitySensorEnabled(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
        if device.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(proximityChanged), name: UIDevice.proximityStateDidChangeNotification, object: device)
        } else {
            NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }
    }

    @objc func didChangeAudioRoute(_ notification: Notification) {
        guard state == .playing else {
            return
        }
        proximityChanged()
    }
    
    @objc func proximityChanged() {
        DispatchQueue.main.async {
            guard !AVAudioSession.sharedInstance().isBluetoothAudioRouteAvailable else {
                return
            }
            let audioSessionUC = AudioSessionUseCase.default
            if UIDevice.current.proximityState {
                audioSessionUC.disableLoudSpeaker()
            } else {
                audioSessionUC.enableLoudSpeaker()
            }
        }
    }

    // MARK: - Methods

    /// Used to configure the audio cell UI:
    ///     1. play button selected state;
    ///     2. progresssView progress;
    ///     3. durationLabel text;
    ///
    /// - Parameters:
    ///   - cell: The `AudioMessageCell` that needs to be configure.
    ///   - message: The `MessageType` that configures the cell.
    ///
    /// - Note:
    ///   This protocol method is called by MessageKit every time an audio cell needs to be configure
    open func configureAudioCell(_ cell: AudioMessageCell, message: any MessageType) {
        
        if isPlayingSameMessage(message),
           let collectionView = messageCollectionView,
           let player = audioPlayer {
            playingCell = cell
            let playerCurrentTime = Float(player.currentTime)
            let playerDuration = Float(player.duration)
            cell.progressView.progress = (playerDuration == 0) ? 0 : playerCurrentTime/playerDuration
            cell.playButton.isSelected = player.isPlaying
            guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                fatalError("MessagesDisplayDelegate has not been set.")
            }
            cell.durationLabel.text = displayDelegate.audioProgressTextFormat(playerCurrentTime, for: cell, in: collectionView)
        }
    }

    /// Used to start play audio sound
    ///
    /// - Parameters:
    ///   - message: The `MessageType` that contain the audio item to be played.
    ///   - audioCell: The `AudioMessageCell` that needs to be updated while audio is playing.
    open func playSound(for message: any MessageType, in audioCell: AudioMessageCell) {
        startAudioPlayerInterruptionIfNeeded()
        
        guard let chatMessage = message as? ChatMessage, let audioCell = audioCell as? ChatVoiceClipCollectionViewCell else {
            return
        }
        
        var path = ""
        
        if let transfer = chatMessage.transfer, transfer.transferChatMessageType() == .voiceClip, let transferPath = transfer.path {
            path = transferPath
        } else if chatMessage.message.type == .voiceClip, let node = chatMessage.message.nodeList?.node(at: 0) {
            path = node.mnz_voiceCachePath()
        } else {
            MEGALogInfo("BasicAudioPlayer failed play sound becasue given message kind is not Audio")
            return
        }
        
        guard FileManager.default.fileExists(atPath: path),
              let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) else {
            MEGALogInfo("Failed to create audio player for URL: \(path)")
            return
        }
        
        playingCell = audioCell
        playingMessage = message
        
        audioCell.waveView.startAnimating()
        audioPlayer = player
        audioPlayer?.prepareToPlay()
        audioPlayer?.delegate = self
        audioPlayer?.play()
        state = .playing
        audioCell.playButton.isSelected = true  // show pause button on audio cell
        startProgressTimer()
        audioCell.delegate?.didStartAudio(in: audioCell)
        setProximitySensorEnabled(true)
        
        AudioSessionUseCase.default.configureChatDefaultAudioPlayer()

        proximityChanged()
    }

    /// Used to pause the audio sound
    ///
    /// - Parameters:
    ///   - message: The `MessageType` that contain the audio item to be pause.
    ///   - audioCell: The `AudioMessageCell` that needs to be updated by the pause action.
    open func pauseSound(for message: any MessageType, in audioCell: AudioMessageCell) {
        guard let audioCell = audioCell as? ChatVoiceClipCollectionViewCell else {
            return
        }
        audioPlayer?.pause()
        state = .pause
        audioCell.playButton.isSelected = false // show play button on audio cell
        progressTimer?.invalidate()
        setProximitySensorEnabled(false)
        if let cell = playingCell {
            cell.delegate?.didPauseAudio(in: cell)
            audioCell.waveView.stopAnimating()
        }
        
        let activeCall = MEGAChatSdk.shared.mnz_existsActiveCall
        endAudioPlayerInterruptionIfNeeded(resume: !activeCall)
    }

    /// Stops any ongoing audio playing if exists
    open func stopAnyOngoingPlaying() {
        guard let player = audioPlayer, let collectionView = messageCollectionView else { return } // If the audio player is nil then we don't need to go through the stopping logic
        player.stop()
        state = .stopped
        if let cell = playingCell {
            guard let audioCell = cell as? ChatVoiceClipCollectionViewCell else {
                return
            }
            audioCell.waveView.stopAnimating()
            
            cell.progressView.progress = 0.0
            cell.playButton.isSelected = false
            guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                fatalError("MessagesDisplayDelegate has not been set.")
            }
            cell.durationLabel.text = displayDelegate.audioProgressTextFormat(Float(player.duration), for: cell, in: collectionView)
            cell.delegate?.didStopAudio(in: cell)
        }
        progressTimer?.invalidate()
        progressTimer = nil
        audioPlayer = nil
        playingMessage = nil
        playingCell = nil
        setProximitySensorEnabled(false)
        
        let activeCall = MEGAChatSdk.shared.mnz_existsActiveCall
        endAudioPlayerInterruptionIfNeeded(resume: !activeCall)
    }

    /// Resume a currently pause audio sound
    open func resumeSound() {
        startAudioPlayerInterruptionIfNeeded()
        
        guard let player = audioPlayer, let cell = playingCell as? ChatVoiceClipCollectionViewCell else {
            stopAnyOngoingPlaying()
            return
        }
        player.prepareToPlay()
        player.play()
        state = .playing
        startProgressTimer()
        cell.playButton.isSelected = true // show pause button on audio cell
        cell.delegate?.didStartAudio(in: cell)
        cell.waveView.startAnimating()
    }

    // MARK: - Fire Methods
    @objc private func didFireProgressTimer(_ timer: Timer) {
        guard let player = audioPlayer, let collectionView = messageCollectionView, let cell = playingCell as? ChatVoiceClipCollectionViewCell else {
            return
        }
        // check if can update playing cell
        if let playingCellIndexPath = collectionView.indexPath(for: cell) {
            // 1. get the current message that decorates the playing cell
            // 2. check if current message is the same with playing message, if so then update the cell content
            // Note: Those messages differ in the case of cell reuse
            if  let currentMessage = collectionView.messagesDataSource?.messageForItem(at: playingCellIndexPath, in: collectionView) as? ChatMessage,
                isPlayingSameMessage(currentMessage) {
                // messages are the same update cell content
                cell.progressView.progress = (player.duration == 0) ? 0 : Float(player.currentTime/player.duration)
                guard let displayDelegate = collectionView.messagesDisplayDelegate else {
                    fatalError("MessagesDisplayDelegate has not been set.")
                }
                cell.durationLabel.text = displayDelegate.audioProgressTextFormat(Float(player.currentTime), for: cell, in: collectionView)
                cell.waveView.startAnimating()
            } else {
                // if the current message is not the same with playing message stop playing sound
                stopAnyOngoingPlaying()
            }
        }
    }
    
    func isPlayingSameMessage(_ message: any MessageType) -> Bool {
        if let playingMessage = playingMessage as? ChatMessage,
           let currentMessage = message as? ChatMessage,
           playingMessage.messageId == currentMessage.messageId || currentMessage.message.nodeList?.node(at: 0)?.name == playingMessage.transfer?.fileName {
            return true
        }
        return false
    }

    // MARK: - Private Methods
    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(BasicAudioController.didFireProgressTimer(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(progressTimer!, forMode: .common)
    }

    // MARK: - AVAudioPlayerDelegate
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAnyOngoingPlaying()
    }
    
    open func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        stopAnyOngoingPlaying()
    }
    
    func startAudioPlayerInterruptionIfNeeded() {
        Task { @MainActor in
            if AudioPlayerManager.shared.isPlayerAlive() {
                AudioPlayerManager.shared.audioInterruptionDidStart()
            }
        }
    }

    func endAudioPlayerInterruptionIfNeeded(resume: Bool) {
        Task { @MainActor in
            if AudioPlayerManager.shared.isPlayerAlive() {
                AudioPlayerManager.shared.audioInterruptionDidEndNeedToResume(resume)
            }
        }
    }
    
    deinit {
        setProximitySensorEnabled(false)
    }
}
