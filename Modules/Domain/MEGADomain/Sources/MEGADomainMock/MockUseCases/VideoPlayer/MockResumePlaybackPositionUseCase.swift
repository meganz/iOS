import Foundation
import MEGADomain

public final class MockResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol, @unchecked Sendable {
    public var savedPositions: [String: TimeInterval] = [:]
    public var savePlaybackPositionCallCount = 0
    public var getPlaybackPositionCallCount = 0
    public var deletePlaybackPositionCallCount = 0

    public init() {}

    public func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode) {
        guard let fingerprint = node.fingerprint else { return }
        savePlaybackPositionCallCount += 1
        savedPositions[fingerprint] = position
    }

    public func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval? {
        guard let fingerprint = node.fingerprint else { return nil }
        getPlaybackPositionCallCount += 1
        return savedPositions[fingerprint]
    }

    public func deletePlaybackPosition(for node: any PlayableNode) {
        deletePlaybackPositionCallCount += 1
    }
}
