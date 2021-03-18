import Foundation

extension AudioPlayer: AudioPlayerStateProtocol {
    
    func setProgressCompleted(_ position: TimeInterval) {
        guard let queuePlayer = queuePlayer, let currentItem = queuePlayer.currentItem else { return }
        currentItem.seek(to: CMTime(seconds: position, preferredTimescale: currentItem.duration.timescale))
        notify(aboutCurrentState)
    }
    
    func resetPlayerItems() {
        guard let queuePlayer = queuePlayer,
              queuePlayer.items().count == 0,
              queuePlayer.currentItem == nil else { return }
            
        resetPlaylist()
    }
    
    func resetPlaylist() {
        var lastItem = queuePlayer?.currentItem as? AudioPlayerItem
        tracks.forEach {
            queuePlayer?.remove($0)
            queuePlayer?.secureInsert($0, after: lastItem)
            lastItem = $0
        }
        
        if let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed {
            play()
        } else {
            pause()
        }
    }
    
    func updateQueueWithLoopItems() {
        guard let queuePlayer = queuePlayer,
              let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where:{$0 == currentItem}) else { return }
        
        if currentIndex == 0 {
            queuePlayer.secureInsert(tracks[tracks.count - 1], after: queuePlayer.items().last)
        } else {
            (0...currentIndex).forEach { index in
                queuePlayer.secureInsert(tracks[index], after: queuePlayer.items().last)
            }
        }
        
        notify(aboutCurrentItemAndQueue)
    }
    
    func removeLoopItems() {
        guard let queuePlayer = queuePlayer,
              let loopAllowed = audioPlayerConfig[.loop] as? Bool, !loopAllowed,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where:{$0 == currentItem}) else { return }
        
        queuePlayer.items().filter({$0 != currentItem}).forEach {
            queuePlayer.remove($0)
        }
        
        ((currentIndex + 1)..<tracks.count).forEach { index in
            queuePlayer.secureInsert(tracks[index], after: queuePlayer.items().last)
        }
    }

    func repeatLastItem() {
        guard queuePlayer != nil,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where:{$0 == currentItem}) else { return }
        
        let lastItem = currentIndex > 0 ? tracks[currentIndex - 1] : nil
        
        if lastItem != nil, itemToRepeat?.node == lastItem?.node {
            notify(aboutTheBeginningOfBlockingAction)
            playPrevious() { [weak self] in
                guard let `self` = self else { return }
                self.notify(self.aboutTheEndOfBlockingAction)
            }
        }
        
        currentItem.seek(to: .zero)
    }
    
    @objc func play() {
        queuePlayer?.play()
        isPaused = false
    }
    
    @objc func pause() {
        queuePlayer?.pause()
        isPaused = true
    }
    
    @objc func togglePlay() {
        isPlaying ? pause() : play()
    }
    
    @objc func playNext(_ completion: @escaping () -> Void) {
        if queuePlayer?.items().count ?? 0 > 1 {
            queuePlayer?.advanceToNextItem()
        } else {
            if queuePlayer?.items().count ?? 0 == tracks.count {
                guard let currentItem = queuePlayer?.currentItem as? AudioPlayerItem else {
                    notify(aboutTheEndOfBlockingAction)
                    return
                }
                
                currentItem.seek(to: .zero) { _ in
                    self.pause()
                    completion()
                    return
                }
            } else {
                resetPlaylist()
            }
        }
        
        completion()
    }
    
    @objc func playPrevious(_ completion: @escaping () -> Void) {
        guard let currentItem = queuePlayer?.currentItem as? AudioPlayerItem else {
            completion()
            return
        }
        
        if let currentIndex = tracks.firstIndex(where:{$0 == currentItem}), currentIndex > 0 {
            let previousItem = tracks[currentIndex - 1]
            queuePlayer?.remove(previousItem)
            queuePlayer?.replaceCurrentItem(with: previousItem)
            queuePlayer?.secureInsert(currentItem, after: previousItem)
            
            previousItem.seek(to: .zero)
            completion()
        } else {
            currentItem.seek(to: .zero) { _ in
                self.isPlaying ? self.play() : self.pause()
                completion()
            }
        }
    }
    
    @objc func play(_ direction: MovementDirection, completion: @escaping () -> Void) {
        direction == .up ? playNext(completion): playPrevious(completion)
    }
    
    @objc func isShuffleMode() -> Bool {
        guard let shuffleMode = audioPlayerConfig[.shuffle] as? Bool else { return false }
        return shuffleMode
    }
    
    @objc func shuffle(_ active: Bool) {
        audioPlayerConfig[.shuffle] = active
        
        if active { shuffleQueue() }
    }
    
    @objc func isRepeatAllMode() -> Bool {
        guard let repeatAllMode = audioPlayerConfig[.loop] as? Bool else { return false }
        return repeatAllMode
    }
    
    @objc func repeatAll(_ active: Bool) {
        audioPlayerConfig[.loop] = active
        itemToRepeat = nil
        if active {
            audioPlayerConfig[.repeatOne] = false
            updateQueueWithLoopItems()
        } else {
            removeLoopItems()
        }
    }
    
    @objc func isRepeatOneMode() -> Bool {
        guard let repeatOneMode = audioPlayerConfig[.repeatOne] as? Bool else { return false }
        return repeatOneMode
    }

    @objc func repeatOne(_ active: Bool) {
        audioPlayerConfig[.repeatOne] = active
        if active {
            itemToRepeat = currentItem()
            audioPlayerConfig[.loop] = false
            removeLoopItems()
        } else { itemToRepeat = nil }
    }
    
    @objc func isDefaultRepeatMode() -> Bool {
        return !isRepeatAllMode() && !isRepeatOneMode()
    }
    
    @objc func setProgressCompleted(_ percentage: Float) {
        guard let queuePlayer = queuePlayer,
              let currentItem = queuePlayer.currentItem else { return }
        let time = CMTime(seconds: CMTimeGetSeconds(currentItem.duration) * Double(percentage), preferredTimescale: currentItem.duration.timescale)
        guard CMTIME_IS_VALID(time) else { return }
        currentItem.seek(to: time)
        notify(aboutCurrentState)
    }
    
    @objc func move(of movedItem: AudioPlayerItem, to position: IndexPath, direction: MovementDirection) {
        guard let queuePlayer = queuePlayer else { return }
        
        notify(aboutTheBeginningOfBlockingAction)
        
        queuePlayer.remove(movedItem)
        movedItem.seek(to: .zero)
        
        let afterItem = queuePlayer.items()[position.previous().row]
        
        if direction == .up {
            guard position.hasPrevious() else {
                insertInQueue(item: movedItem, afterItem: nil)
                notify(aboutTheEndOfBlockingAction)
                return
            }
            insertInQueue(item: movedItem, afterItem: afterItem as? AudioPlayerItem)
            if let trackPosition = tracks.firstIndex(where:{$0 == afterItem as? AudioPlayerItem}) {
                tracks.move(movedItem, to: trackPosition + 1)
            }
            
        } else {
            insertInQueue(item: movedItem, afterItem: afterItem as? AudioPlayerItem)
            if let trackPosition = tracks.firstIndex(where:{$0 == afterItem as? AudioPlayerItem}) {
                tracks.move(movedItem, to: trackPosition)
            }
        }
        
        notify(aboutTheEndOfBlockingAction)
    }

    @objc func deletePlaylist(items: [AudioPlayerItem]) {
        guard let player = queuePlayer else { return }
        
        let itemsToRemove = items.filter{$0 != currentItem()}
        itemsToRemove.forEach(player.remove)
        
        notify([aboutCurrentItemAndQueue])
        update(tracks: tracks.filter{!itemsToRemove.contains($0)})
    }
    
    @objc func playerCurrentTime() -> TimeInterval { currentTime }
    
    @objc func refreshCurrentItemState() {
        notify(aboutCurrentState)
    }
    
    func blockAudioPlayerInteraction() {
        notify(aboutTheBeginningOfBlockingAction)
    }
    
    func unblockAudioPlayerInteraction() {
        notify(aboutTheEndOfBlockingAction)
    }
    
    func insertInQueue(item: AudioPlayerItem, afterItem: AudioPlayerItem?) {
        queuePlayer?.secureInsert(item, after: afterItem)
        
        if let items = queuePlayer?.items() as? [AudioPlayerItem] {
            update(tracks: items)
        }
        
        notify([aboutCurrentItemAndQueue, aboutTheEndOfBlockingAction])
    }
    
    func reset(item: AudioPlayerItem) {
        item.seek(to: .zero)
    }
}

extension AVQueuePlayer {
    func secureInsert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
        guard items().filter({item == $0}).isEmpty else { return }
        insert(item, after: afterItem)
    }
}
