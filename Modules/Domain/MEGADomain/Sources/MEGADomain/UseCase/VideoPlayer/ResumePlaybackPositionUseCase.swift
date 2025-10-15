import Foundation
import MEGAPreference

public protocol ResumePlaybackPositionUseCaseProtocol: Sendable {
    /// Saves the current playback position for a specific video node
    func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode)
    
    /// Retrieves the saved playback position for a specific video node
    func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval?

    /// Delete the saved playback position for a specific video node
    func deletePlaybackPosition(for node: any PlayableNode)
}

public struct ResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol {
    @PreferenceWrapper(key: VideoPlayerPreferenceKeyEntity.playbackResumePositions, defaultValue: [:])
    private var playbackResumePositions: [String: TimeInterval]

    public init(
        preferenceUseCase: any PreferenceUseCaseProtocol
    ) {
        $playbackResumePositions.useCase = preferenceUseCase
    }
    
    public func savePlaybackPosition(_ position: TimeInterval, for node: any PlayableNode) {
        guard let fingerprint = node.fingerprint else { return }
        playbackResumePositions[fingerprint] = position
    }
    
    public func getPlaybackPosition(for node: any PlayableNode) -> TimeInterval? {
        guard let fingerprint = node.fingerprint else { return nil }
        return playbackResumePositions[fingerprint]
    }

    public func deletePlaybackPosition(for node: any PlayableNode) {
        guard let fingerprint = node.fingerprint else { return }
        playbackResumePositions.removeValue(forKey: fingerprint)
    }
}
