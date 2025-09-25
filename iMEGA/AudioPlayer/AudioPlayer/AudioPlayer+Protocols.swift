import AVFoundation
import Foundation
import MediaPlayer
import MEGAAppPresentation
import MEGADomain

protocol AudioPlayerProtocol: AnyObject {}

// MARK: - Audio Player Metadata Functions
protocol AudioPlayerMetadataLoaderProtocol {
    func preloadNextTracksMetadata()
}

// MARK: - Audio Player Observers Functions
protocol AudioPlayerObserversProtocol: AudioPlayerProtocol {
    func audio(player: AVQueuePlayer, showLoading: Bool)
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?)
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String)
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?)
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?)
    func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool)
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?)
    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?)
    func audio(player: AVQueuePlayer, loopMode: Bool, shuffleMode: Bool, repeatOneMode: Bool)
    func audioPlayerWillStartBlockingAction()
    func audioPlayerDidFinishBlockingAction()
    func audioPlayerDidPausePlayback()
    func audioPlayerDidResumePlayback()
    func audioPlayerDidFinishBuffering()
    func audioPlayerDidAddTracks()
    func audioDidStartPlayingItem(_ item: AudioPlayerItem?)
}

/// Default Observer Callbacks (Optional-by-default)
/// To keep adopters from having to implement every callback, we provide empty default implementations here. This mirrors
/// Objective-C’s `@objc optional` behavior while staying in pure Swift
extension AudioPlayerObserversProtocol {
    func audio(player: AVQueuePlayer, showLoading: Bool) {}
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?) {}
    func audio(player: AVQueuePlayer, name: String, artist: String, thumbnail: UIImage?, url: String) {}
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, currentThumbnail: UIImage?) {}
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, queue: [AudioPlayerItem]?) {}
    func audio(player: AVQueuePlayer, currentTime: Double, remainingTime: Double, percentageCompleted: Float, isPlaying: Bool) {}
    func audio(player: AVQueuePlayer, currentItem: AudioPlayerItem?, indexPath: IndexPath?) {}
    func audio(player: AVQueuePlayer, reload item: AudioPlayerItem?) {}
    func audio(player: AVQueuePlayer, loopMode: Bool, shuffleMode: Bool, repeatOneMode: Bool) {}
    func audioPlayerWillStartBlockingAction() {}
    func audioPlayerDidFinishBlockingAction() {}
    func audioPlayerDidPausePlayback() {}
    func audioPlayerDidResumePlayback() {}
    func audioPlayerDidFinishBuffering() {}
    func audioPlayerDidAddTracks() {}
    func audioDidStartPlayingItem(_ item: AudioPlayerItem?) {}
}

// MARK: - Audio Player Handler
@MainActor protocol AudioPlayerHandlerProtocol:
    AudioPlayerCurrentStatusProtocol &
    AudioPlayerPlaybackProtocol &
    AudioPlayerConfigurationProtocol {}

// MARK: - Audio Player Current Status Functions
@MainActor protocol AudioPlayerCurrentStatusProtocol: AnyObject {
    func isPlayerDefined() -> Bool
    func isPlayerEmpty() -> Bool
    func isShuffleEnabled() -> Bool
    func isSingleItemPlaylist() -> Bool
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
    /// Retrieves the upcoming playlist items from the player. We use it to know which tracks of the playlist we should show in the Playlist screen.
    /// - Returns: An array of `AudioPlayerItem` representing the upcoming tracks in the playback queue. This mirrors the `upcomingPlaylist` property on the player,
    ///   excluding the current item, and wraps around if looping is enabled.
    func upcomingPlaylistItems() -> [AudioPlayerItem]
}

// MARK: - Audio Player Playback Functions
@MainActor protocol AudioPlayerPlaybackProtocol: AnyObject {
    func move(item: AudioPlayerItem, to position: IndexPath, direction: MovementDirection)
    func delete(items: [AudioPlayerItem]) async
    func playerProgressCompleted(percentage: Float)
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
    func resetCurrentItem(shouldResetPlayback: Bool)
    func resettingAudioPlayer(shouldResetPlayback: Bool)
}

// MARK: - Audio Player Configuration Functions
@MainActor protocol AudioPlayerConfigurationProtocol: AnyObject {
    func setCurrent(player: AudioPlayer?, tracks: [AudioPlayerItem], playerListener: any AudioPlayerObserversProtocol)
    func addPlayer(tracks: [AudioPlayerItem])
    func configurePlayer(listener: any AudioPlayerObserversProtocol)
    func removePlayer(listener: any AudioPlayerObserversProtocol)
    func updateMiniPlayerPresenter(_ presenter: any AudioPlayerPresenterProtocol)
    func addMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol)
    func removeMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol)
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: HandleEntity, chatId: HandleEntity, isFromSharedItem: Bool, allNodes: [MEGANode]?)
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool, isFromSharedItem: Bool)
    func playerHidden(_ hidden: Bool, presenter: UIViewController)
    func closePlayer()
    func dismissFullScreenPlayer() async
    func presentMiniPlayer(_ viewController: UIViewController)
    func audioInterruptionDidStart()
    func audioInterruptionDidEndNeedToResume(_ resume: Bool)
    func remoteCommandEnabled(_ enabled: Bool)
    func resetAudioPlayerConfiguration()
    func refreshContentOffset(presenter: any AudioPlayerPresenterProtocol, isHidden: Bool)
}

// MARK: - Mini Audio Player Handlers Functions
protocol AudioMiniPlayerHandlerProtocol: AudioPlayerProtocol, AnyObject {
    /// Presents the mini player view controller at the bottom of the screen.
    /// - Parameters:
    ///   - viewController: The view controller whose view will be used as the mini player UI.
    ///   - height: The default height, in points, to assign to the mini player container.
    func presentMiniPlayer(_ viewController: UIViewController, height: CGFloat)
    func showMiniPlayer()
    func hideMiniPlayer()
    func closeMiniPlayer()
    func resetMiniPlayerContainer()
    func currentContainerHeight() -> CGFloat
    func containsMiniPlayerInstance() -> Bool
}
