import Foundation
import MEGAPreference

public protocol ResumePlaybackPositionUseCaseProtocol {
    /// Saves the current playback position for a specific video node
    func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode)
    
    /// Retrieves the saved playback position for a specific video node
    func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval?

    /// Delete the saved playback position for a specific video node
    func deletePlaybackPosition(for node: any PlayableNode)
}

public final class ResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol {
    @PreferenceWrapper(key: VideoPlayerPreferenceKeyEntity.playbackResumePositions, defaultValue: [:])
    private var playbackResumePositions: [String: TimeInterval]

    public init(
        preferenceUseCase: any PreferenceUseCaseProtocol
    ) {
        $playbackResumePositions.useCase = preferenceUseCase
    }
    
    public func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode) {
        playbackResumePositions[node.id] = position
    }
    
    public func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval? {
        playbackResumePositions[node.id]
    }

    public func deletePlaybackPosition(for node: any PlayableNode) {
        playbackResumePositions.removeValue(forKey: node.id)
    }
}
