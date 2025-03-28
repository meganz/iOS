import Foundation

enum RewindDirection {
    case backward, forward
}

// MARK: - Audio Player Control State Functions
extension AudioPlayer {
    
    private func refreshCurrentState(refresh: Bool) {
        if refresh {
            notify(aboutCurrentState)
            refreshNowPlayingInfo()
        }
    }
    
    private func updatePlayerRateIfNeeded() {
        guard let rate = storedRate else { return }
        if rate != 0.0 {
            queuePlayer?.rate = rate
            storedRate = 0.0
        }
    }

    func setProgressCompleted(_ position: TimeInterval) {
        setProgressCompleted(position, completion: { })
    }
    
    func setProgressCompleted(_ position: TimeInterval, completion: @escaping () -> Void) {
        guard let queuePlayer = queuePlayer, let currentItem = queuePlayer.currentItem else { return }
        
        let time = CMTime(seconds: position, preferredTimescale: currentItem.duration.timescale)
        guard CMTIME_IS_VALID(time) else {
            MEGALogDebug("[AudioPlayer] setProgressCompleted invalid time: \(time) timeInterval: \(position)")
            audioSeekFallbackObserver = currentItem.observe(
                \.duration,
                 changeHandler: { [weak self] item, _ in
                     if CMTIME_IS_VALID(
                        CMTime(seconds: position, preferredTimescale: item.duration.timescale)
                     ) {
                         self?.setProgressCompleted(position, completion: completion)
                     }
                 }
            )
            return
        }

        notify(aboutShowingLoadingView)
        Task { @MainActor in
            let isFinished = await currentItem.seek(to: time)
            refreshCurrentState(refresh: isFinished)
            completion()
        }

        audioSeekFallbackObserver?.invalidate()
    }
    
    func resetPlayerItems() {
        guard let queuePlayer = queuePlayer,
              queuePlayer.items().isEmpty,
              queuePlayer.currentItem == nil else { return }
            
        resetPlaylist()
    }
    
    func resetPlaylist() {
        guard let queuePlayer = queuePlayer else { return }
        tracks.forEach {
            queuePlayer.remove($0)
            queuePlayer.secureInsert($0, after: queuePlayer.items().last)
        }
        
        if let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed {
            play()
        } else {
            pause()
        }
    }
    
    func resetAudioPlayerConfiguration() {
        audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
    }
    
    func updateQueueWithLoopItems() {
        // Only in case, the loader has no more batches in progress or pending, we call `updateQueueWithLoopItems()` to add items
        // to the audio player, ensuring the audio playback can continue seamlessly.
        guard !queueLoader.hasPendingWork,
              let queuePlayer = queuePlayer,
              let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where: { $0 == currentItem }) else { return }
        
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
              let currentIndex = tracks.firstIndex(where: { $0 == currentItem }) else { return }
        
        queuePlayer.items().filter({$0 != currentItem}).forEach {
            queuePlayer.remove($0)
        }
        
        ((currentIndex + 1)..<tracks.count).forEach { index in
            queuePlayer.secureInsert(tracks[index], after: queuePlayer.items().last)
        }
        
        notify(aboutCurrentItemAndQueue)
    }

    func repeatLastItem() {
        guard let queuePlayer = queuePlayer else { return }
        
        // the current item is nil only when the audio player has played the last track of the playlist
        if currentItem() == nil {
            guard let lastItem = tracks.last else { return }
            
            let resumePlaying = isPlaying
            
            if resumePlaying {
                pause()
            }
            queuePlayer.secureInsert(lastItem, after: nil)
            
            if resumePlaying {
                play()
            }
            
        } else {
            guard let currentItem = currentItem(),
                  let currentIndex = tracks.firstIndex(where: { $0 == currentItem }) else { return }
            
            let lastItem = currentIndex > 0 ? tracks[currentIndex - 1] : nil
            
            if let lastItem = lastItem,
               let itemToRepeat = itemToRepeat,
               lastItem == itemToRepeat {
                notify(aboutTheBeginningOfBlockingAction)
                playPrevious { [weak self] in
                    guard let `self` = self else { return }
                    self.notify(self.aboutTheEndOfBlockingAction)
                }
            }
            
            Task { @MainActor in
                _ = await currentItem.seek(to: .zero)
            }
        }
    }
    
    @objc func play() {
        queuePlayer?.play()
        updatePlayerRateIfNeeded()
        isPaused = false
    }
    
    @objc func pause() {
        guard let queuePlayer = queuePlayer else { return }
        storedRate = queuePlayer.rate
        queuePlayer.pause()
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
                    completion()
                    return
                }
                Task { @MainActor in
                    _ = await currentItem.seek(to: .zero)
                    pause()
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
        guard let queuePlayer = queuePlayer,
              let currentIndex = tracks.firstIndex(where: {$0 == currentItem()}) else {
            completion()
            return
        }
        
        if currentIndex > 0 {
            let previousItem = tracks[currentIndex - 1]
            play(item: previousItem, completion: completion)
        } else {
            storedRate = rate
            Task { @MainActor in
                let isFinished = await queuePlayer.currentItem?.seek(to: .zero)
                if isFinished == true {
                    isPlaying ? play() : pause()
                    completion()
                }
            }
        }
    }
    
    @objc func play(item: AudioPlayerItem, completion: @escaping () -> Void) {
        guard let queuePlayer = queuePlayer,
              let index = tracks.firstIndex(where: {$0 == item}),
              let currentIndex = tracks.firstIndex(where: {$0 == currentItem()}) else {
            completion()
            return
        }
        
        if currentIndex > index {
            queuePlayer.remove(item)
            queuePlayer.secureInsert(item, after: queuePlayer.currentItem)
            Task { @MainActor in
                _ = await item.seek(to: .zero)
            }

            if let currentItem = queuePlayer.currentItem {
                queuePlayer.remove(currentItem)
                queuePlayer.secureInsert(currentItem, after: item)
            }
        } else if currentIndex == index {
            Task { @MainActor in
                let isFinished = await queuePlayer.currentItem?.seek(to: .zero)
                if isFinished == true {
                    completion()
                    return
                }
            }
        } else {
            queuePlayer.items()
                .compactMap { $0 as? AudioPlayerItem }
                .filter({
                    guard let trackIndex = tracks.firstIndex(of: $0),
                          trackIndex < index else { return false }
                    return true
                }).forEach {
                    queuePlayer.remove($0)
                }
        }
        
        completion()
    }
    
    func rewind(direction: RewindDirection) {
        guard let queuePlayer = queuePlayer,
              let currentItem = queuePlayer.currentItem,
              CMTIME_IS_VALID(currentItem.duration),
              currentItem.duration >= .zero else { return }
        
        switch direction {
        case .backward:
            rewindBackward(completion: refreshCurrentState)
        case .forward:
            rewindForward(duration: currentItem.duration, completion: refreshCurrentState)
        }
    }
    
    func rewindBackward(completion: @escaping (Bool) -> Void) {
        guard let queuePlayer = queuePlayer,
              let currentItem = queuePlayer.currentItem,
              CMTIME_IS_VALID(queuePlayer.currentTime()) else {
            completion(false)
            return
        }
        
        let futureTime = queuePlayer.currentTime() - CMTime(seconds: defaultRewindInterval, preferredTimescale: currentItem.duration.timescale)
        
        guard CMTIME_IS_VALID(futureTime) else {
            completion(false)
            return
        }
        
        Task { @MainActor in
            _ = await queuePlayer.seek(to: futureTime < .zero ? .zero : futureTime)
            completion(true)
        }
    }
    
    func rewindForward(duration: CMTime, completion: @escaping (Bool) -> Void) {
        guard let queuePlayer = queuePlayer,
              let currentItem = queuePlayer.currentItem,
              CMTIME_IS_VALID(queuePlayer.currentTime()),
              CMTIME_IS_VALID(duration) else {
            completion(false)
            return
        }
        
        let futureTime = queuePlayer.currentTime() + CMTime(seconds: defaultRewindInterval, preferredTimescale: currentItem.duration.timescale)
        
        guard CMTIME_IS_VALID(futureTime) else {
            completion(false)
            return
        }
        
        Task { @MainActor in
            _ = await queuePlayer.seek(to: futureTime > duration ? duration : futureTime)
            completion(true)
        }
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
        
        setProgressCompleted(CMTimeGetSeconds(currentItem.duration) * Double(percentage))
    }
    
    @objc func progressDragEventBegan() {
        invalidateTimer()
    }
    
    @objc func progressDragEventEnded() {
        setTimer()
    }
    
    @objc func move(of movedItem: AudioPlayerItem, to position: IndexPath, direction: MovementDirection) {
        guard let queuePlayer = queuePlayer else { return }
        
        notify(aboutTheBeginningOfBlockingAction)
        
        queuePlayer.remove(movedItem)
        Task { @MainActor in
            _ = await movedItem.seek(to: .zero)
        }
        
        let afterItem = queuePlayer.items()[position.previous().row]
        
        if direction == .up {
            guard position.hasPrevious() else {
                insertInQueue(item: movedItem, afterItem: nil)
                notify(aboutTheEndOfBlockingAction)
                return
            }
            insertInQueue(item: movedItem, afterItem: afterItem as? AudioPlayerItem)
            if let trackPosition = tracks.firstIndex(where: { $0 == afterItem as? AudioPlayerItem }) {
                tracks.move(movedItem, to: trackPosition + 1)
            }
            
        } else {
            insertInQueue(item: movedItem, afterItem: afterItem as? AudioPlayerItem)
            if let trackPosition = tracks.firstIndex(where: { $0 == afterItem as? AudioPlayerItem }) {
                tracks.move(movedItem, to: trackPosition)
            }
        }
        notify(aboutTheEndOfBlockingAction)
    }
    
    func shuffleQueue() {
        guard let queuePlayer = queuePlayer,
              let currentItem = currentItem() else { return }
        
        notify(aboutTheBeginningOfBlockingAction)
        
        var playerPlaylist: [AudioPlayerItem] = queuePlayer.items()
                                                           .compactMap({ $0 as? AudioPlayerItem})
                                                           .filter({$0 != currentItem})
        
        playerPlaylist.shuffle()
        
        // Update the "tracks" array with the correct position for the current audio player playlist
        let finalTracks = Array(Set(tracks).subtracting(playerPlaylist)) + playerPlaylist
        update(tracks: finalTracks)
        
        // remove all playlist tracks except the current item
        queuePlayer.items().filter({$0 != currentItem}).forEach {
            queuePlayer.remove($0)
        }
        
        // reset the playlist by inserting the following playlist items
        playerPlaylist.forEach { queuePlayer.secureInsert($0, after: queuePlayer.items().last) }
        
        // Update the queue loader's state to match the new shuffled order
        queueLoader.shuffleTracks()
        
        notify(aboutTheEndOfBlockingAction)
    }

    @objc func deletePlaylist(items: [AudioPlayerItem]) {
        guard let player = queuePlayer else { return }
        
        let itemsToRemove = items.filter { $0 != currentItem() }
        itemsToRemove.forEach(player.remove)
        
        notify([aboutCurrentItemAndQueue])
        update(tracks: tracks.filter { !itemsToRemove.contains($0) })
    }
    
    @objc func playerCurrentTime() -> TimeInterval { currentTime }
    
    @objc func refreshCurrentItemState() {
        notify([aboutCurrentState, aboutCurrentItem])
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
        
        notify([aboutTheEndOfBlockingAction])
    }
    
    func reset(item: AudioPlayerItem) {
        Task { @MainActor in
            _ = await item.seek(to: .zero)
        }
    }
    
    func resetCurrentItem() {
        guard let currentItem = currentItem() else { return }
        
        let shouldResetPlayback = resettingPlayback
        let resumePlaying = isPlaying || (isPaused && shouldResetPlayback)
        
        if resumePlaying {
            pause()
        }
        
        reset(item: currentItem)
        
        if resumePlaying {
            play()
            if shouldResetPlayback {
                resettingPlayback = false
            }
        }
    }
}

extension AVQueuePlayer {
    func secureInsert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
        guard items().notContains(where: { item == $0 }) else { return }
        if canInsert(item, after: afterItem), item.status != .failed {
            insert(item, after: afterItem)
        }
    }
}
