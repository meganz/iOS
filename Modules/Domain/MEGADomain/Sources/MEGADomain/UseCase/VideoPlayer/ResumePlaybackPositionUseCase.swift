import Foundation
import MEGAPreference

/// Remembers where each video was left off.
///
/// Positions are stored against the fingerprint the SDK computes from the file's contents rather than
/// against a node, so the same video resumes at the same place whether it is streamed from the cloud
/// or played from the copy the user downloaded. Items that cannot be fingerprinted are not remembered.
public protocol ResumePlaybackPositionUseCaseProtocol: Sendable {
    /// Saves the current playback position for the video this item plays
    func savePlaybackPosition(_ position: TimeInterval, for item: VideoPlaybackItem)

    /// Retrieves the saved playback position for the video this item plays
    func playbackPosition(for item: VideoPlaybackItem) -> TimeInterval?

    /// Delete the saved playback position for the video this item plays
    func deletePlaybackPosition(for item: VideoPlaybackItem)
}

public struct ResumePlaybackPositionUseCase: ResumePlaybackPositionUseCaseProtocol {
    @PreferenceWrapper(key: VideoPlayerPreferenceKeyEntity.playbackResumePositions, defaultValue: [:])
    private var playbackResumePositions: [String: TimeInterval]

    private let fileFingerprintRepository: any FileFingerprintRepositoryProtocol

    public init(
        preferenceUseCase: any PreferenceUseCaseProtocol,
        fileFingerprintRepository: any FileFingerprintRepositoryProtocol
    ) {
        self.fileFingerprintRepository = fileFingerprintRepository
        $playbackResumePositions.useCase = preferenceUseCase
    }

    public func savePlaybackPosition(_ position: TimeInterval, for item: VideoPlaybackItem) {
        guard let fingerprint = fingerprint(of: item) else { return }
        playbackResumePositions[fingerprint] = position
    }

    public func playbackPosition(for item: VideoPlaybackItem) -> TimeInterval? {
        guard let fingerprint = fingerprint(of: item) else { return nil }
        return playbackResumePositions[fingerprint]
    }

    public func deletePlaybackPosition(for item: VideoPlaybackItem) {
        guard let fingerprint = fingerprint(of: item) else { return }
        playbackResumePositions.removeValue(forKey: fingerprint)
    }

    /// A cloud node comes with the SDK's fingerprint on it; a file on the device is fingerprinted on
    /// the spot. Both end up with the same value for the same video.
    private func fingerprint(of item: VideoPlaybackItem) -> String? {
        switch item {
        case .node(let node): node.fingerprint
        case .offlineFile(let url): fileFingerprintRepository.fingerprint(forFileAt: url)
        }
    }
}
