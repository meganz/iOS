import MEGAAccountManagement
import MEGASdk
import MEGASDKRepo
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var nodes: [MEGANode]?

    var selectedPlayerOption: VideoPlayerOption {
        get { selectPlayerUseCase.selectedPlayer }
        set { selectPlayerUseCase.selectPlayer(newValue) }
    }

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
        path.append(node)
    }

    func didTapLogout() async {
        await offboardingUseCase.activeLogout()
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
            selectPlayerUseCase: DependencyInjection.selectVideoPlayerOptionUseCase
        )
    }
}
