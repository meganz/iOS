import MEGAAnalyticsiOS
import MEGAAppPresentation
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
    private let tracker: any AnalyticsTracking

    convenience init(
        homeDeepLink: HomeDeepLink,
    ) {
        self.init(
            homeDeepLink: homeDeepLink,
            networkMonitoringUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            tracker: DIContainer.tracker
        )
    }

    package init(
        homeDeepLink: HomeDeepLink,
        networkMonitoringUseCase: some NetworkMonitorUseCaseProtocol,
        tracker: some AnalyticsTracking
    ) {
        self.homeDeepLink = homeDeepLink
        self.networkMonitoringUseCase = networkMonitoringUseCase
        self.isSearching = homeDeepLink.homeSearch
        self.tracker = tracker
        isNetworkConnected = networkMonitoringUseCase.isConnected()
    }

    func togglePresentSheet() {
        tracker.trackAnalyticsEvent(with: HomeFabOptionsButtonPressedEvent())
        presentsSheet.toggle()
    }

    func trackHomeScreenAppear() {
        tracker.trackAnalyticsEvent(with: HomeScreenEvent())
    }

    func monitorNetworkConnection() async {
        for await connected in networkMonitoringUseCase.connectionSequence {
            isNetworkConnected = connected
        }
    }

    func observeDeepLinkSearch() async {
        for await homeSearch in homeDeepLink.$homeSearch.values.dropFirst() {
            isSearching = homeSearch
        }
    }

    func monitorSearchBarPressed() async {
        for await isSearching in $isSearching.values.dropFirst() {
            guard isSearching else { continue }
            tracker.trackAnalyticsEvent(with: HomeSearchBarPressedEvent())
        }
    }
}
