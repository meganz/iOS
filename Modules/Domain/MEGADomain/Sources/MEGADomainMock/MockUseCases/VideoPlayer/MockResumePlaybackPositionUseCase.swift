import Foundation
import MEGADomain

/// Files positions under each item's `playbackID`; resolving the fingerprint is the real use case's job.
public final class MockResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol, @unchecked Sendable {
    public var savedPositions: [String: TimeInterval] = [:]
    public var savePlaybackPositionCallCount = 0
    public var getPlaybackPositionCallCount = 0
    public var deletePlaybackPositionCallCount = 0

    public init() {}

    public func savePlaybackPosition(_ position: TimeInterval, for item: VideoPlaybackItem) {
        savePlaybackPositionCallCount += 1
        savedPositions[item.playbackID] = position
    }

    public func playbackPosition(for item: VideoPlaybackItem) -> TimeInterval? {
        getPlaybackPositionCallCount += 1
        return savedPositions[item.playbackID]
    }

    public func deletePlaybackPosition(for item: VideoPlaybackItem) {
        deletePlaybackPositionCallCount += 1
        savedPositions.removeValue(forKey: item.playbackID)
    }
}
