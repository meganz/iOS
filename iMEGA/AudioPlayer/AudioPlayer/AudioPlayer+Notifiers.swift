import Foundation

// MARK: - Audio Player Notify Observers Functions
extension AudioPlayer: AudioPlayerProtocol {
    func notify(_ closure: (any AudioPlayerObserversProtocol) -> Void) {
        notifyObservers(closure)
    }
    
    func notify(_ closures: [(any AudioPlayerObserversProtocol) -> Void]) {
        closures.forEach(notify(_:))
    }
    
    func aboutCurrentState(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer, let currentState, !currentState.currentTime.isNaN, !currentState.remainingTime.isNaN, !currentState.percentage.isNaN else { return }
        
        observer.audio(player: queuePlayer, currentTime: currentState.currentTime, remainingTime: currentState.remainingTime, percentageCompleted: currentState.percentage, isPlaying: currentState.isPlaying)
    }
    
    func aboutCurrentItem(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        
        if currentNode != nil, let currentItem = currentItem() {
            observer.audio(player: queuePlayer, name: currentName ?? "", artist: currentArtist ?? "", thumbnail: currentThumbnail, url: currentItem.url.absoluteString)
        } else {
            observer.audio(player: queuePlayer, name: currentName ?? "", artist: currentArtist ?? "", thumbnail: currentThumbnail)
        }
    }
    
    func aboutCurrentThumbnail(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer, let currentItem = currentItem() else { return }
        
        observer.audio(player: queuePlayer, currentItem: currentItem, currentThumbnail: currentThumbnail)
    }
    
    func aboutToReloadCurrentItem(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        
        observer.audio(player: queuePlayer, reload: currentItem())
    }
    
    func aboutCurrentItemAndQueue(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        
        observer.audio(player: queuePlayer, currentItem: currentItem(), queue: queueItems())
    }
    
    func aboutTheBeginningOfBlockingAction(_ observer: any AudioPlayerObserversProtocol) {
        observer.audioPlayerWillStartBlockingAction()
    }
    
    func aboutTheEndOfBlockingAction(_ observer: any AudioPlayerObserversProtocol) {
        observer.audioPlayerDidFinishBlockingAction()
    }
    
    func aboutShowingLoadingView(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        observer.audio(player: queuePlayer, showLoading: true)
    }
    
    func aboutHidingLoadingView(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        observer.audio(player: queuePlayer, showLoading: false)
    }
    
    func aboutUpdateCurrentIndexPath(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        
        if let currentIndex = tracks.firstIndex(where: { $0 == currentItem() }) {
            observer.audio(player: queuePlayer, currentItem: currentItem(), indexPath: IndexPath(row: currentIndex, section: 0))
        }
    }
    
    func notifyAboutToReload(item: AudioPlayerItem) {
        guard let queuePlayer else { return }
        
        notifyObservers { $0.audio(player: queuePlayer, reload: item) }
    }
    
    func aboutAudioPlayerConfiguration(_ observer: any AudioPlayerObserversProtocol) {
        guard let queuePlayer else { return }
        
        observer.audio(player: queuePlayer, loopMode: isRepeatAllMode(), shuffleMode: isShuffleMode(), repeatOneMode: isRepeatOneMode())
    }
    
    func aboutAudioPlayerDidFinishBuffering(_ observer: any AudioPlayerObserversProtocol) {
        observer.audioPlayerDidFinishBuffering()
    }
    
    func aboutStartPlayingNewItem(_ observer: any AudioPlayerObserversProtocol) {
        observer.audioDidStartPlayingItem(currentItem())
    }
    
    func aboutAudioPlayerDidAddTracks(_ observer: any AudioPlayerObserversProtocol) {
        observer.audioPlayerDidAddTracks()
    }
}
