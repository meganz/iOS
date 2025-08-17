import MEGAVideoPlayer
import SwiftUI

@MainActor
public struct VideoPlayerFactory {
    private let selectPlayerUseCase: any SelectVideoPlayerUseCaseProtocol

    public init(selectPlayerUseCase: some SelectVideoPlayerUseCaseProtocol) {
        self.selectPlayerUseCase = selectPlayerUseCase
    }

    public func playerViewModel(for node: (any PlayableNode)? = nil) -> MEGAPlayerViewModel {
        MEGAPlayerViewModel(player: player(for: node))
    }

    private func player(for node: (any PlayableNode)?) -> any VideoPlayerProtocol {
        switch (node, selectPlayerUseCase.selectedPlayer) {
        case (.some(let node), .avPlayer):
            MEGAAVPlayer.liveValue(node: node)
        case (.none, .avPlayer):
            MEGAAVPlayer.liveValue
        default:
            MEGAAVPlayer.liveValue
        }
    }
}

public extension VideoPlayerFactory {
    static var liveValue: VideoPlayerFactory {
        VideoPlayerFactory(
            selectPlayerUseCase: MEGAVideoPlayer.DependencyInjection.selectVideoPlayerOptionUseCase
        )
    }
}
