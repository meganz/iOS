import Foundation
import MEGADomain

public final class MockResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol {
    public var savedPositions: [String: TimeInterval] = [:]
    public var savePlaybackPositionCallCount = 0
    public var getPlaybackPositionCallCount = 0
    public var deletePlaybackPositionCallCount = 0

    public init() {}

    public func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode) {
        savePlaybackPositionCallCount += 1
        savedPositions[node.id] = position
    }

    public func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval? {
        getPlaybackPositionCallCount += 1
        return savedPositions[node.id]
    }

    public func deletePlaybackPosition(for node: any PlayableNode) {
        deletePlaybackPositionCallCount += 1
    }
}
