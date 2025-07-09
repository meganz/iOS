protocol SelectVideoPlayerUseCaseProtocol {
    var selectedPlayer: VideoPlayerOption { get }

    func selectPlayer(_ player: VideoPlayerOption)
}

/// In-memory selected player is only temporary.
///
/// This will be refactored to use some persistent solution in the future.
final class SelectVideoPlayerUseCase: SelectVideoPlayerUseCaseProtocol {
    static let shared = SelectVideoPlayerUseCase()

    private init() {}

    var selectedPlayer: VideoPlayerOption = .vlc

    func selectPlayer(_ player: VideoPlayerOption) {
        selectedPlayer = player
    }
}
