import Combine
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
    
    func setProgressCompleted(_ position: TimeInterval) async {
        isUpdatingProgress = true
        defer { isUpdatingProgress = false }
        
        guard let queuePlayer, let currentItem = queuePlayer.currentItem else { return }
        
        var target = CMTime(seconds: position, preferredTimescale: currentItem.duration.timescale)
        
        if !CMTIME_IS_VALID(target) {
            MEGALogDebug("[AudioPlayer] setProgressCompleted invalid time: \(target) timeInterval: \(position)")
            await waitUntilSeekTimeIsValid(for: currentItem, position: position)
            target = CMTime(seconds: position, preferredTimescale: currentItem.duration.timescale)
            guard CMTIME_IS_VALID(target) else {
                MEGALogDebug("[AudioPlayer] setProgressCompleted still invalid after wait: \(target)")
                return
            }
        }
        
        let finished = await currentItem.seek(to: target)
        refreshCurrentState(refresh: finished)
    }
    
    private func waitUntilSeekTimeIsValid(for item: AVPlayerItem, position: TimeInterval) async {
        let initial = CMTime(seconds: position, preferredTimescale: item.duration.timescale)
        if CMTIME_IS_VALID(initial) { return }
        
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = item.publisher(for: \.duration, options: .new)
                .receive(on: DispatchQueue.main)
                .first { newDuration in
                    CMTIME_IS_VALID(CMTime(seconds: position, preferredTimescale: newDuration.timescale))
                }
                .sink { _ in
                    cancellable?.cancel()
                    continuation.resume()
                }
            
        }
    }
    
    func resetPlayerItems() {
        guard let queuePlayer,
              queuePlayer.items().isEmpty,
              queuePlayer.currentItem == nil else { return }
            
        resetPlaylist()
    }
    
    func resetPlaylist() {
        guard let queuePlayer else { return }
        tracks.forEach {
            queuePlayer.remove($0)
            queuePlayer.secureInsert($0, after: queuePlayer.items().last)
        }
        
        if let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed {
            play()
        } else {
            pause()
        }
        
        notify(aboutCurrentItemAndQueue)
    }
    
    func resetAudioPlayerConfiguration() {
        audioPlayerConfig = [.loop: false, .shuffle: false, .repeatOne: false]
    }
    
    func updateQueueWithLoopItems() {
        /// Only in case, the loader has no more batches in progress or pending, we call `updateQueueWithLoopItems()` to add items
        /// to the audio player, ensuring the audio playback can continue seamlessly.
        guard !queueLoader.hasPendingWork,
              let queuePlayer,
              let loopAllowed = audioPlayerConfig[.loop] as? Bool, loopAllowed,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where: { $0 == currentItem }) else { return }
        
        let itemsToInsert: [AudioPlayerItem]
        if currentIndex == 0 {
            guard let last = tracks.last else { return }
            itemsToInsert = [last]
        } else {
            itemsToInsert = Array(tracks[0...currentIndex])
        }
        
        for item in itemsToInsert {
            queuePlayer.secureInsert(item, after: queuePlayer.items().last)
        }
        
        notify(aboutCurrentItemAndQueue)
    }
    
    func removeLoopItems() {
        /// Only in case, the loader has no more batches in progress or pending, we call `removeLoopItems()` to remove previously
        /// loop-inserted items from the audio player, ensuring the playback queue reflects the disabled loop mode seamlessly.
        guard !queueLoader.hasPendingWork,
              let queuePlayer,
              let loopAllowed = audioPlayerConfig[.loop] as? Bool, !loopAllowed,
              let currentItem = currentItem(),
              let currentIndex = tracks.firstIndex(where: { $0 == currentItem }) else { return }
        
        queuePlayer.items().filter({ $0 != currentItem }).forEach {
            queuePlayer.remove($0)
        }
        
        for index in ((currentIndex + 1)..<tracks.count) {
            queuePlayer.secureInsert(tracks[index], after: queuePlayer.items().last)
        }
        
        notify(aboutCurrentItemAndQueue)
    }

    func repeatLastItem() {
        guard let queuePlayer else { return }
        
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
    
    func play() {
        queuePlayer?.play()
        updatePlayerRateIfNeeded()
        isPaused = false
    }
    
    func pause() {
        guard let queuePlayer else { return }
        storedRate = queuePlayer.rate
        queuePlayer.pause()
        isPaused = true
    }
    
    func togglePlay() {
        isPlaying ? pause() : play()
    }
    
    func playNext(_ completion: @escaping () -> Void) {
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
    
    func playPrevious(_ completion: @escaping () -> Void) {
        guard let queuePlayer,
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
    
    func play(item: AudioPlayerItem, completion: @escaping () -> Void) {
        guard let queuePlayer,
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
        guard let queuePlayer,
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
        guard let queuePlayer,
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
        guard let queuePlayer,
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
    
    func isShuffleMode() -> Bool {
        guard let shuffleMode = audioPlayerConfig[.shuffle] as? Bool else { return false }
        return shuffleMode
    }
    
    func shuffle(_ active: Bool) {
        audioPlayerConfig[.shuffle] = active
        
        if active {
            shuffleQueue()
        }
    }
    
    func isRepeatAllMode() -> Bool {
        guard let repeatAllMode = audioPlayerConfig[.loop] as? Bool else { return false }
        return repeatAllMode
    }
    
    func repeatAll(_ active: Bool) {
        audioPlayerConfig[.loop] = active
        itemToRepeat = nil
        if active {
            audioPlayerConfig[.repeatOne] = false
            updateQueueWithLoopItems()
        } else {
            removeLoopItems()
        }
    }
    
    func isRepeatOneMode() -> Bool {
        guard let repeatOneMode = audioPlayerConfig[.repeatOne] as? Bool else { return false }
        return repeatOneMode
    }

    func repeatOne(_ active: Bool) {
        audioPlayerConfig[.repeatOne] = active
        if active {
            itemToRepeat = currentItem()
            audioPlayerConfig[.loop] = false
            removeLoopItems()
        } else { itemToRepeat = nil }
    }
    
    func isDefaultRepeatMode() -> Bool {
        !isRepeatAllMode() && !isRepeatOneMode()
    }
    
    func move(of movedItem: AudioPlayerItem, to position: IndexPath, direction: MovementDirection) {
        guard let queuePlayer else { return }
        
        notify(aboutTheBeginningOfBlockingAction)
        
        /// Capture the current playback queue to determine if the item is already enqueued.
        let queueItems = queuePlayer.items().compactMap { $0 as? AudioPlayerItem }
        let isInQueue = queueItems.contains(movedItem)
        
        if isInQueue {
            /// If the item is already in the queue, remove it so we can reinsert at the new position.
            queuePlayer.remove(movedItem)
            
            Task { @MainActor in
                _ = await movedItem.seek(to: .zero)
            }
            
            /// If moving up and there's no valid previous position, insert at the front.
            if direction == .up, !position.hasPrevious() {
                insertInQueue(item: movedItem, afterItem: nil)
                notify(aboutTheEndOfBlockingAction)
                return
            }
            
            let prevIndex = position.previous().row
            let items = queuePlayer.items()
            let afterItem: AudioPlayerItem? = items.indices.contains(prevIndex) ? items[prevIndex] as? AudioPlayerItem : nil
            
            insertInQueue(item: movedItem, afterItem: afterItem)
            if let anchor = afterItem,
               let trackPosition = tracks.firstIndex(where: { $0 == anchor }) {
                /// We add 1 because we want movedItem to appear immediately after the anchor item.
                tracks.move(movedItem, to: trackPosition + 1)
            }
        } else {
            tracks.move(movedItem, to: position.row)
            
            if position.row < queueItems.count {
                let afterItem: AudioPlayerItem? = position.row > 0 ? queueItems[position.row - 1] : nil
                insertInQueue(item: movedItem, afterItem: afterItem)
            }
        }
        
        /// The moved item might have been outside the currently enqueued batch and therefore its metadata wasn’t yet loaded.
        /// Trigger metadata preloading for whatever is now in the queue so any newly exposed or repositioned items have their artwork/details ready.
        preloadNextTracksMetadata()
        
        notify(aboutTheEndOfBlockingAction)
    }
    
    func shuffleQueue() {
        guard let queuePlayer,
              let currentItem = currentItem() else { return }
        
        /// Shuffle everything except the currently playing item in place.
        if tracks.count > 2 {
            tracks[1...].shuffle()
        }
        
        /// Update full playlist order to reflect shuffle.
        update(tracks: tracks)
        
        /// Remove everything from the AVQueuePlayer except the current item so we can rebuild the playback queue.
        for case let item as AudioPlayerItem in queuePlayer.items() where item !== currentItem {
            queuePlayer.remove(item)
        }
        
        /// Reset the loader to consider the newly shuffled full playlist, then get the first batch to enqueue.
        queueLoader.reset()
        let initialBatch = queueLoader.addAllTracks(tracks)
        
        /// Enqueue the initial batch after the current item, preserving batch order.
        var tail: AVPlayerItem? = currentItem
        for item in initialBatch {
            queuePlayer.secureInsert(item, after: tail)
            tail = item
        }
        
        /// Begin preloading metadata only for the newly enqueued items so their artwork/details are ready.
        preloadNextTracksMetadata()
    }
    
    func deletePlaylist(items: [AudioPlayerItem]) async {
        guard let queuePlayer else { return }
        
        let itemsToRemove = items.filter { $0 != currentItem() }
        itemsToRemove.forEach(queuePlayer.remove)
        
        update(tracks: tracks.filter { !itemsToRemove.contains($0) })
        notify([aboutCurrentItemAndQueue])
    }
    
    func playerCurrentTime() -> TimeInterval { currentTime }
    
    func refreshCurrentItemState() {
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
        
        if let existingIndex = tracks.firstIndex(where: { $0 == item }) {
            tracks.remove(at: existingIndex)
        }
        
        let insertionIndex: Int
        if let afterItem, afterItem != item, let afterIndex = tracks.firstIndex(where: { $0 == afterItem }) {
            insertionIndex = afterIndex + 1
        } else {
            insertionIndex = 0
        }
        
        tracks.insert(item, at: insertionIndex)
        
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
