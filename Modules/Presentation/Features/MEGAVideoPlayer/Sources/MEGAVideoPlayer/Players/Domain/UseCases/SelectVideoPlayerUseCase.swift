public protocol SelectVideoPlayerUseCaseProtocol {
    var selectedPlayer: VideoPlayerOption { get }

    func selectPlayer(_ player: VideoPlayerOption)
}

/// In-memory selected player is only temporary.
///
/// This will be refactored to use some persistent solution in the future.
public final class SelectVideoPlayerUseCase: SelectVideoPlayerUseCaseProtocol {
    public init() {}

    public var selectedPlayer: VideoPlayerOption = .avPlayer

    public func selectPlayer(_ player: VideoPlayerOption) {
        selectedPlayer = player
    }
}
