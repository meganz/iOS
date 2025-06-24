/// A wrapper that manages an AVQueuePlayer time observer.
/// On initialization, adds the periodic time observer to the given player.
/// On deinitialization, removes the observer from the player automatically.
final class AudioPlayerTimeObserver {
    private weak var player: AVQueuePlayer?
    private var token: Any?

    init(
      player: AVQueuePlayer?,
      interval: CMTime,
      queue: DispatchQueue = .main,
      handler: @escaping (CMTime) -> Void
    ) {
        self.player = player
        self.token = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: queue,
            using: handler
        )
    }

    /// Automatically removes the time observer when this object is deallocated. This ensures removal from the same player instance that added it,
    /// preventing potential mismatches and runtime exceptions.
    deinit {
        if let player, let token {
            player.removeTimeObserver(token)
        }
    }
}
