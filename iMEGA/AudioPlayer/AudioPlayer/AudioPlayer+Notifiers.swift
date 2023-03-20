import Foundation

extension AudioPlayer: AudioPlayerNotifyObserversProtocol {
    
    func notify(_ closure: (AudioPlayerObserversProtocol) -> Void) {
        listenerManager.notify(closure: closure)
    }
    
    func notify(_ closures: [(AudioPlayerObserversProtocol) -> Void]) {
        closures.forEach(notify(_:))
    }
    
    func aboutCurrentState(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer, let currentState = currentState, !currentState.currentTime.isNaN, !currentState.remainingTime.isNaN, !currentState.percentage.isNaN else { return }
        
        observer.audio?(player: player, currentTime: currentState.currentTime, remainingTime: currentState.remainingTime, percentageCompleted: currentState.percentage, isPlaying: currentState.isPlaying)
    }
    
    func aboutCurrentItem(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        
        if currentNode != nil, let currentItem = currentItem() {
            observer.audio?(player: player, name: currentName ?? "", artist: currentArtist ?? "", album: currentAlbum ?? "", thumbnail: currentThumbnail, url: currentItem.url.absoluteString)
        } else {
            observer.audio?(player: player, name: currentName ?? "", artist: currentArtist ?? "", album: currentAlbum ?? "", thumbnail: currentThumbnail)
        }
    }
    
    func aboutCurrentThumbnail(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer, let currentItem = currentItem() else { return }
        
        observer.audio?(player: player, currentItem: currentItem, currentThumbnail: currentThumbnail)
    }
    
    func aboutToReloadCurrentItem(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        
        observer.audio?(player: player, reload: currentItem())
    }
    
    func aboutCurrentItemAndQueue(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        
        observer.audio?(player: player, currentItem: currentItem(), queue: queueItems())
    }
    
    func aboutTheBeginningOfBlockingAction(_ observer: AudioPlayerObserversProtocol) {
        observer.audioPlayerWillStartBlockingAction?()
    }
    
    func aboutTheEndOfBlockingAction(_ observer: AudioPlayerObserversProtocol) {
        observer.audioPlayerDidFinishBlockingAction?()
    }
    
    func aboutShowingLoadingView(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        observer.audio?(player: player, showLoading: true)
    }
    
    func aboutHidingLoadingView(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        observer.audio?(player: player, showLoading: false)
    }
    
    func aboutUpdateCurrentIndexPath(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        
        if let currentIndex = tracks.firstIndex(where:{$0 == currentItem()}) {
            observer.audio?(player: player, currentItem: currentItem(), indexPath: IndexPath(row: currentIndex, section: 0))
        }
    }
    
    func notifyAboutToReload(item: AudioPlayerItem) {
        guard let player = queuePlayer else { return }
        
        listenerManager.notify{$0.audio?(player: player, reload: item)}
    }
    
    func aboutAudioPlayerDidPausePlayback(_ observer: AudioPlayerObserversProtocol) {
        observer.audioPlayerDidPausePlayback?()
    }
    
    func aboutAudioPlayerDidResumePlayback(_ observer: AudioPlayerObserversProtocol) {
        observer.audioPlayerDidResumePlayback?()
    }
    
    func aboutAudioPlayerConfiguration(_ observer: AudioPlayerObserversProtocol) {
        guard let player = queuePlayer else { return }
        
        observer.audio?(player: player, loopMode: isRepeatAllMode(), shuffleMode: isShuffleMode(), repeatOneMode: isRepeatOneMode())
    }
    
    func aboutAudioPlayerDidFinishBuffering(_ observer: AudioPlayerObserversProtocol) {
        observer.audioPlayerDidFinishBuffering?()
    }
}
