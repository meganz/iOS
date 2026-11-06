import Foundation
import os

/// Keeps the current stage of every upload operation, so the Pipeline now group can count files per stage at any moment.
final class CameraUploadPipelineMonitor: Sendable {
    struct Counts {
        var queued = 0
        var fetching = 0
        var exporting = 0
        var thumbnailing = 0
        var encrypting = 0
        var requestingUploadURL = 0
        var videosPreparing = 0
    }

    private struct Entry {
        let stage: CameraUploadPipelineStage
        let isVideo: Bool
    }

    private let entries = OSAllocatedUnfairLock(initialState: [ObjectIdentifier: Entry]())

    func setStage(_ stage: CameraUploadPipelineStage, for operation: AnyObject, isVideo: Bool) {
        let key = ObjectIdentifier(operation)
        let entry = Entry(stage: stage, isVideo: isVideo)
        entries.withLock { $0[key] = entry }
    }

    func remove(_ operation: AnyObject) {
        let key = ObjectIdentifier(operation)
        _ = entries.withLock { $0.removeValue(forKey: key) }
    }

    func counts() -> Counts {
        let current = entries.withLock { Array($0.values) }
        return current.reduce(into: Counts()) { counts, entry in
            switch entry.stage {
            case .queued: counts.queued += 1
            case .fetching: counts.fetching += 1
            case .exporting: counts.exporting += 1
            case .thumbnailing: counts.thumbnailing += 1
            case .encrypting: counts.encrypting += 1
            case .requestingUploadURL: counts.requestingUploadURL += 1
            }
            if entry.stage.isPreparing && entry.isVideo {
                counts.videosPreparing += 1
            }
        }
    }
}
