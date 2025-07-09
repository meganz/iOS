import SwiftUI

@MainActor
struct VideoPlayerFactory {
    private let selectPlayerUseCase: any SelectVideoPlayerUseCaseProtocol

    init(selectPlayerUseCase: some SelectVideoPlayerUseCaseProtocol) {
        self.selectPlayerUseCase = selectPlayerUseCase
    }

    func playerViewModel(for node: (any PlayableNode)? = nil) -> MEGAPlayerViewModel {
        MEGAPlayerViewModel(player: player(for: node))
    }

    private func player(for node: (any PlayableNode)?) -> any VideoPlayerProtocol {
        switch (node, selectPlayerUseCase.selectedPlayer) {
        case (.some(let node), .vlc):
            MEGAVLCPlayer.liveValue(node: node)
        case (.some(let node), .avPlayer):
            MEGAAVPlayer.liveValue(node: node)
        case (.none, .vlc):
            MEGAVLCPlayer.liveValue
        case (.none, .avPlayer):
            MEGAAVPlayer.liveValue
        }
    }
}

extension VideoPlayerFactory {
    static var liveValue: VideoPlayerFactory {
        VideoPlayerFactory(selectPlayerUseCase: SelectVideoPlayerUseCase.shared)
    }
}
