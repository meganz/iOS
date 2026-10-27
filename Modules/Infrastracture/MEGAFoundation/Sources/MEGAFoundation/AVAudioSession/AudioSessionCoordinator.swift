import Foundation

/// The app has one `AVAudioSession`, shared by every player. Deactivating it pauses every player still
/// running, such as a video in Picture in Picture, so each player holds the session under its own owner
/// id while it plays, and only the last one to let go deactivates it.
public final class AudioSessionCoordinator: @unchecked Sendable {
    public static let shared = AudioSessionCoordinator()

    private let lock = NSLock()
    private var owners: Set<String> = []

    public init() {}

    /// Holds the session for `owner`. Holding it again under the same owner changes nothing.
    public func acquire(_ owner: String) {
        lock.withLock { _ = owners.insert(owner) }
    }

    /// Lets go of the session `owner` holds.
    /// - Returns: `true` when no other owner holds the session, so the caller can deactivate it.
    @discardableResult
    public func release(_ owner: String) -> Bool {
        lock.withLock {
            owners.remove(owner)
            return owners.isEmpty
        }
    }
}
