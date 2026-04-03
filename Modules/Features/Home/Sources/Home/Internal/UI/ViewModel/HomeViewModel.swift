import Combine
import MEGAAppSDKRepo
import MEGADomain

@MainActor
final class HomeViewModel: ObservableObject {

    let widgets: [HomeWidgetType] = [.shortcuts, .accountDetails, .promotionalBanners, .recents]
    @Published var isSearching: Bool
    @Published var presentsSheet = false
    @Published var hidesFloatingActionsButton: Bool = false
    @Published var isNetworkConnected = false
    private let homeDeepLink: HomeDeepLink
    private let networkMonitoringUseCase: any NetworkMonitorUseCaseProtocol

    convenience init(
        homeDeepLink: HomeDeepLink
    ) {
        self.init(
            homeDeepLink: homeDeepLink,
            networkMonitoringUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
        )
    }

    package init(
        homeDeepLink: HomeDeepLink,
        networkMonitoringUseCase: some NetworkMonitorUseCaseProtocol
    ) {
        self.homeDeepLink = homeDeepLink
        self.networkMonitoringUseCase = networkMonitoringUseCase
        self.isSearching = homeDeepLink.homeSearch
        isNetworkConnected = networkMonitoringUseCase.isConnected()
        
        homeDeepLink
            .$homeSearch
            .dropFirst()
            .assign(to: &$isSearching)
    }

    func onTask() async {
        for await connected in networkMonitoringUseCase.connectionSequence {
            isNetworkConnected = connected
        }
    }
}
