import AVFoundation
import Foundation
import MediaPlayer
import MEGADomain

@objc protocol AudioPlayerProtocol: AnyObject {}

// MARK: - Audio Player Control State Functions
protocol AudioPlayerStateProtocol {
    func play()
    func pause()
    func togglePlay()
    func playNext(_ completion: @escaping () -> Void)
    func playPrevious(_ completion: @escaping () -> Void)
    func play(item: AudioPlayerItem, completion: @escaping () -> Void)
    func rewind(direction: RewindDirection)
    func isShuffleMode() -> Bool
    func shuffle(_ active: Bool)
    func isRepeatAllMode() -> Bool
    func repeatAll(_ active: Bool)
    func isRepeatOneMode() -> Bool
    func repeatOne(_ active: Bool)
    func isDefaultRepeatMode() -> Bool
    func setProgressCompleted(_ percentage: Float)
    func setProgressCompleted(_ position: TimeInterval)
    func progressDragEventBegan()
    func progressDragEventEnded()
    func move(of movedItem: AudioPlayerItem, to position: IndexPath, direction: MovementDirection)
    func deletePlaylist(items: [AudioPlayerItem])
    func resetPlayerItems()
    func updateQueueWithLoopItems()
    func removeLoopItems()
    func repeatLastItem()
    func resetPlaylist()
    func resetAudioPlayerConfiguration()
    func blockAudioPlayerInteraction()
    func unblockAudioPlayerInteraction()
    func resetCurrentItem()
}

// MARK: - Audio Player Time Functions
protocol AudioPlayerTimerProtocol {
    func setTimer()
    func invalidateTimer()
}

// MARK: - Audio Player Remote Command Functions
protocol AudioPlayerRemoteCommandProtocol {
    func audioPlayer(didReceivePlayCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func audioPlayer(didReceivePauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func audioPlayer(didReceiveNextTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func audioPlayer(didReceivePreviousTrackCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func audioPlayer(didReceiveTogglePlayPauseCommand event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func audioPlayer(didReceiveChangePlaybackPositionCommand event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus
}

// MARK: - Audio Player Metadata Functions
protocol AudioPlayerMetadataLoaderProtocol {
    func preloadNextTracksMetadata()
}

// MARK: - Audio Player Observed Events Functions
protocol AudioPlayerObservedEventsProtocol {
    func audio(player: AVQueuePlayer, didChangeItem value: NSKeyValueObservedChange<AVPlayerItem?>)
    func audio(player: AVQueuePlayer, didChangeTimeControlStatus value: NSKeyValueObservedChange<AVQueuePlayer.TimeControlStatus>)
    func audio(player: AVQueuePlayer, reasonForWaitingToPlay value: NSKeyValueObservedChange<AVQueuePlayer.WaitingReason?>)
    func audio(playerItem: AVPlayerItem, didChangeCurrentItemStatus value: NSKeyValueObservedChange<AVPlayerItem.Status>)
    func audio(playerItem: AVPlayerItem, isPlaybackBufferEmpty value: NSKeyValueObservedChange<Bool>)
    func audio(playerItem: AVPlayerItem, isPlaybackLikelyToKeepUp value: NSKeyValueObservedChange<Bool>)
    func audio(playerItem: AVPlayerItem, isPlaybackBufferFull value: NSKeyValueObservedChange<Bool>)
}

// MARK: - Audio Player Observers Functions
@objc protocol AudioPlayerObserversProtocol: AudioPlayerProtocol {
    @objc optional func audio(player: AVQueuePlayer, showLoading: Bool)
    @objc optional func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?)
    @objc optional func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String)
    @objc optional func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?)
    @objc optional func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?)
    @objc optional func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool)
    @objc optional func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?)
    @objc optional func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?)
    @objc optional func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, entireQueue: [AudioPlayerItem]?)
    @objc optional func audio(player: AVQueuePlayer, loopMode: Bool, shuffleMode: Bool, repeatOneMode: Bool)
    @objc optional func audioPlayerWillStartBlockingAction()
    @objc optional func audioPlayerDidFinishBlockingAction()
    @objc optional func audioPlayerDidPausePlayback()
    @objc optional func audioPlayerDidResumePlayback()
    @objc optional func audioPlayerDidFinishBuffering()
    @objc optional func audioPlayerDidAddTracks()
    @objc optional func audioDidStartPlayingItem(_ item: AudioPlayerItem?)
}

// MARK: - Audio Player Notify Observers Functions
protocol AudioPlayerNotifyObserversProtocol: AudioPlayerProtocol {
    func notify(_ closure: (AudioPlayerObserversProtocol) -> Void)
    func notify(_ closures: [(AudioPlayerObserversProtocol) -> Void])
    func aboutCurrentState(_ observer: AudioPlayerObserversProtocol)
    func aboutCurrentItem(_ observer: AudioPlayerObserversProtocol)
    func aboutToReloadCurrentItem(_ observer: AudioPlayerObserversProtocol)
    func aboutCurrentItemAndQueue(_ observer: AudioPlayerObserversProtocol)
    func aboutCurrentThumbnail(_ observer: AudioPlayerObserversProtocol)
    func aboutTheBeginningOfBlockingAction(_ observer: AudioPlayerObserversProtocol)
    func aboutTheEndOfBlockingAction(_ observer: AudioPlayerObserversProtocol)
    func aboutShowingLoadingView(_ observer: AudioPlayerObserversProtocol)
    func aboutHidingLoadingView(_ observer: AudioPlayerObserversProtocol)
    func aboutUpdateCurrentIndexPath(_ observer: AudioPlayerObserversProtocol)
    func aboutAudioPlayerDidPausePlayback(_ observer: AudioPlayerObserversProtocol)
    func aboutAudioPlayerDidResumePlayback(_ observer: AudioPlayerObserversProtocol)
    func aboutAudioPlayerConfiguration(_ observer: AudioPlayerObserversProtocol)
    func aboutAudioPlayerDidFinishBuffering(_ observer: AudioPlayerObserversProtocol)
    func aboutStartPlayingNewItem(_ observer: AudioPlayerObserversProtocol)
    func aboutAudioPlayerDidAddTracks(_ observer: AudioPlayerObserversProtocol)
}

// MARK: - Audio Player Handler
@objc protocol AudioPlayerHandlerProtocol: AudioPlayerCurrentStatusProtocol & AudioPlayerPlaybackProtocol & AudioPlayerConfigurationProtocol {}

// MARK: - Audio Player Current Status Functions
@objc protocol AudioPlayerCurrentStatusProtocol: AnyObject {
    func isPlayerDefined() -> Bool
    func isPlayerEmpty() -> Bool
    func isShuffleEnabled() -> Bool
    func autoPlay(enable: Bool)
    func isPlayerPlaying() -> Bool
    func isPlayerPaused() -> Bool
    func isPlayerAlive() -> Bool
    func currentPlayer() -> AudioPlayer?
    func currentRepeatMode() -> RepeatMode
    func currentSpeedMode() -> SpeedMode
    func playerCurrentItem() -> AudioPlayerItem?
    func playerCurrentItemTime() -> TimeInterval
    func playerQueueItems() -> [AudioPlayerItem]?
    func playerPlaylistItems() -> [AudioPlayerItem]?
    func playerTracksContains(url: URL) -> Bool
}

// MARK: - Audio Player Playback Functions
@objc protocol AudioPlayerPlaybackProtocol: AnyObject {
    func move(item: AudioPlayerItem, to position: IndexPath, direction: MovementDirection)
    func delete(items: [AudioPlayerItem])
    func playerProgressCompleted(percentage: Float)
    func playerProgressDragEventBegan()
    func playerProgressDragEventEnded()
    func playerShuffle(active: Bool)
    func goBackward()
    func playPrevious()
    func playerTogglePlay()
    func playerPause()
    func playerPlay()
    func playerResumePlayback(from timeInterval: TimeInterval)
    func playNext()
    func goForward()
    func play(item: AudioPlayerItem)
    func playerRepeatAll(active: Bool)
    func playerRepeatOne(active: Bool)
    func playerRepeatDisabled()
    func changePlayer(speed: SpeedMode)
    func refreshCurrentItemState()
    func resetCurrentItem()
}

// MARK: - Audio Player Configuration Functions
@objc protocol AudioPlayerConfigurationProtocol: AnyObject {
    func setCurrent(player: AudioPlayer?, autoPlayEnabled: Bool, tracks: [AudioPlayerItem])
    func addPlayer(tracks: [AudioPlayerItem])
    func addPlayer(listener: AudioPlayerObserversProtocol)
    func removePlayer(listener: AudioPlayerObserversProtocol)
    func addDelegate(_ delegate: AudioPlayerPresenterProtocol)
    func removeDelegate(_ delegate: AudioPlayerPresenterProtocol)
    func addMiniPlayerHandler(_ handler: AudioMiniPlayerHandlerProtocol)
    func removeMiniPlayerHandler(_ handler: AudioMiniPlayerHandlerProtocol)
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: HandleEntity, chatId: HandleEntity)
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool)
    func playerHidden(_ hidden: Bool, presenter: UIViewController)
    func closePlayer()
    func presentMiniPlayer(_ viewController: UIViewController)
    func audioInterruptionDidStart()
    func audioInterruptionDidEndNeedToResume(_ resume: Bool)
    func remoteCommandEnabled(_ enabled: Bool)
    func resetAudioPlayerConfiguration()
}

// MARK: - Mini Audio Player Handlers Functions
@objc protocol AudioMiniPlayerHandlerProtocol: AudioPlayerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController)
    func showMiniPlayer()
    func hideMiniPlayer()
    func closeMiniPlayer()
    func resetMiniPlayerContainer()
}

// MARK: - Audio Player Presenters
@objc protocol AudioPlayerPresenterProtocol: AudioPlayerProtocol {
    func updateContentView(_ height: CGFloat)
}

final class ListenerManager<T: AudioPlayerProtocol> {
    var listeners: [T] = []
    
    func add(_ listener: T) {
        listeners.append(listener)
    }
    func remove(_ listener: T) {
        listeners = listeners.filter { $0 !== listener }
    }
    func notify(closure: (T) -> Void) {
        listeners.forEach(closure)
    }
}
