import Combine
import CoreGraphics
import MEGAAppSDKRepo
import MEGADomain

@MainActor
final class HomeViewModel: ObservableObject {

    let widgets: [HomeWidgetType] = [.shortcuts, .accountDetails, .promotionalBanners, .recents]
    @Published var isSearching: Bool = false
    @Published var presentsSheet = false
    @Published var hidesFloatingActionsButton: Bool = false
    @Published var isNetworkConnected = false
    @Published var transferProgress: CGFloat = 0.0
    
    private let networkMonitoringUseCase: any NetworkMonitorUseCaseProtocol

    convenience init() {
        self.init(networkMonitoringUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo))
    }

    package init(networkMonitoringUseCase: some NetworkMonitorUseCaseProtocol) {
        self.networkMonitoringUseCase = networkMonitoringUseCase
        isNetworkConnected = networkMonitoringUseCase.isConnected()
    }

    func onTask() async {
        for await connected in networkMonitoringUseCase.connectionSequence {
            isNetworkConnected = connected
        }
    }
}
