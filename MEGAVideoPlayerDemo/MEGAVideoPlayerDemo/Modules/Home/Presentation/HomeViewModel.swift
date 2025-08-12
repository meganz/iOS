import MEGAAccountManagement
import MEGASdk
import MEGASDKRepo
import MEGAVideoPlayer
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedVideoNode: MEGANode?
    @Published var nodes: [MEGANode]?

    @Published private(set) var selectedPlayerOption: VideoPlayerOption = .vlc

    private let fetchVideoNodesUseCase: any FetchVideoNodesUseCaseProtocol
    private let offboardingUseCase: any OffboardingUseCaseProtocol
    private let selectPlayerUseCase: any SelectVideoPlayerUseCaseProtocol

    init(
        fetchVideoNodesUseCase: some FetchVideoNodesUseCaseProtocol,
        offboardingUseCase: some OffboardingUseCaseProtocol,
        selectPlayerUseCase: some SelectVideoPlayerUseCaseProtocol
    ) {
        self.fetchVideoNodesUseCase = fetchVideoNodesUseCase
        self.offboardingUseCase = offboardingUseCase
        self.selectPlayerUseCase = selectPlayerUseCase
    }

    func viewWillAppear() async {
        await streamNodes()
    }

    func didTapNode(_ node: MEGANode) {
        selectedPlayerOption = selectPlayerUseCase.selectedPlayer
        selectedVideoNode = node
    }

    func didTapLogout() async {
        await offboardingUseCase.activeLogout()
    }

    func didSelectPlayerOption(_ option: VideoPlayerOption) {
        selectedPlayerOption = option
        selectPlayerUseCase.selectPlayer(option)
    }

    private func streamNodes() async {
        for await videoNodes in fetchVideoNodesUseCase.stream() {
            guard !Task.isCancelled else { return }
            nodes = videoNodes
        }
    }
}

extension HomeViewModel {
    static var liveValue: HomeViewModel {
        HomeViewModel(
            fetchVideoNodesUseCase: DependencyInjection.fetchVideoNodesUseCase,
            offboardingUseCase: DependencyInjection.offboardingUseCase,
            selectPlayerUseCase: MEGAVideoPlayer.DependencyInjection.selectVideoPlayerOptionUseCase
        )
    }
}
