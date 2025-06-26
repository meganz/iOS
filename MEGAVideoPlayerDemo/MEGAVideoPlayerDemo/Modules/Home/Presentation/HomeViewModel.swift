import MEGAAccountManagement
import MEGASdk
import MEGASDKRepo
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var nodes: [MEGANode]?

    private(set) var refreshNodeListTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private(set) var monitorNodesUpdatesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    private let fetchVideoNodesUseCase: any FetchVideoNodesUseCaseProtocol
    private let nodesUpdatesStream: any NodesUpdatesStreamProtocol
    private let offboardingUseCase: any OffboardingUseCaseProtocol

    init(
        fetchVideoNodesUseCase: some FetchVideoNodesUseCaseProtocol,
        nodesUpdatesStream: some NodesUpdatesStreamProtocol,
        offboardingUseCase: some OffboardingUseCaseProtocol,
    ) {
        self.fetchVideoNodesUseCase = fetchVideoNodesUseCase
        self.nodesUpdatesStream = nodesUpdatesStream
        self.offboardingUseCase = offboardingUseCase
    }

    func viewWillAppear() async {
        refreshNodeList()
        monitorNodesUpdates()
    }

    func onDisappear() {
        refreshNodeListTask = nil
        monitorNodesUpdatesTask = nil
    }

    func didTapNode(_ node: MEGANode) {
        path.append(node)
    }

    func didTapLogout() async {
        await offboardingUseCase.activeLogout()
    }

    private func refreshNodeList() {
        refreshNodeListTask = Task { [weak self, fetchVideoNodesUseCase] in
            let megaNodeList = fetchVideoNodesUseCase.execute()
            guard !Task.isCancelled else { return }
            self?.nodes = megaNodeList
        }
    }

    private func monitorNodesUpdates() {
        monitorNodesUpdatesTask = Task { [weak self, nodesUpdatesStream] in
            for await updates in nodesUpdatesStream.onNodesUpdateStream where updates.toArray.isNotEmpty {
                guard !Task.isCancelled else { return }
                self?.refreshNodeList()
            }
        }
    }
}

extension HomeViewModel {
    static var liveValue: HomeViewModel {
        HomeViewModel(
            fetchVideoNodesUseCase: DependencyInjection.fetchVideoNodesUseCase,
            nodesUpdatesStream: MEGAUpdateHandlerManager.shared,
            offboardingUseCase: DependencyInjection.offboardingUseCase
        )
    }
}
