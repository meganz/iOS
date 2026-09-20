import Foundation
import MEGADomain

/// What a Cloud Drive deletion means for the queue that is playing.
enum QueueDeletionOutcome {
    /// Nothing the queue holds was deleted.
    case unaffected
    /// Deleted tracks dropped. Whatever is playing was not one of them and keeps going.
    case dropped(PlaybackQueue)
    /// The track that was playing is gone, and this queue is anchored on the one that takes over from it
    case skipped(PlaybackQueue)
    /// Every track in the queue is gone.
    case emptied
}

extension PlaybackQueue {
    /// Reconciles the queue against nodes that have left the Cloud Drive
    ///
    /// - Parameter deletedNodeHandles: the handles that have gone
    func applyingDeletion(ofNodeHandles deletedNodeHandles: Set<HandleEntity>) -> QueueDeletionOutcome {
        let deletedTrackIDs = Set(
            tracks
                .filter { track in
                    guard case .account(let node) = track else { return false }
                    return deletedNodeHandles.contains(node.handle)
                }
                .map(\.id)
        )
        guard !deletedTrackIDs.isEmpty else { return .unaffected }

        let survivors = tracks.filter { !deletedTrackIDs.contains($0.id) }
        guard !survivors.isEmpty else { return .emptied }

        guard let currentTrack = current, deletedTrackIDs.contains(currentTrack.id) else {
            let index = current
                .flatMap { current in survivors.firstIndex { $0.id == current.id } }
                ?? currentIndex
            return .dropped(PlaybackQueue(tracks: survivors, currentIndex: index))
        }

        let successor = nextSurvivor(excluding: deletedTrackIDs)
        let index = successor
            .flatMap { successor in survivors.firstIndex { $0.id == successor.id } }
            ?? 0
        return .skipped(PlaybackQueue(tracks: survivors, currentIndex: index))
    }

    /// The first track after the current one that survives the deletion, wrapping around the end of the queue
    private func nextSurvivor(excluding deletedTrackIDs: Set<String>) -> PlaybackTrack? {
        guard !tracks.isEmpty else { return nil }

        for offset in 1...tracks.count {
            let candidate = tracks[(currentIndex + offset) % tracks.count]
            guard !deletedTrackIDs.contains(candidate.id) else { continue }
            return candidate
        }
        return nil
    }
}
