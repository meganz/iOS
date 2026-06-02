import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var widgets: [HomeWidgetType] = []
    @Published var isSearching: Bool
    @Published var presentsSheet = false
    @Published var hidesFloatingActionsButton: Bool = false
    @Published var isNetworkConnected = false
    private let homeDeepLink: HomeDeepLink
    private let networkMonitoringUseCase: any NetworkMonitorUseCaseProtocol
    private let widgetDisplayUseCase: any HomeWidgetDisplayUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    convenience init(
        homeDeepLink: HomeDeepLink,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.init(
            homeDeepLink: homeDeepLink,
            networkMonitoringUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            widgetDisplayUseCase: HomeWidgetDisplayUseCase(),
            tracker: DIContainer.tracker,
            featureFlagProvider: featureFlagProvider
        )
    }

    package init(
        homeDeepLink: HomeDeepLink,
        networkMonitoringUseCase: some NetworkMonitorUseCaseProtocol,
        widgetDisplayUseCase: some HomeWidgetDisplayUseCaseProtocol,
        tracker: some AnalyticsTracking,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.homeDeepLink = homeDeepLink
        self.networkMonitoringUseCase = networkMonitoringUseCase
        self.widgetDisplayUseCase = widgetDisplayUseCase
        self.isSearching = homeDeepLink.homeSearch
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
        isNetworkConnected = networkMonitoringUseCase.isConnected()
    }

    func reloadWidgets() {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo) else {
            widgets = HomeWidgetType.phase1Widgets
            return
        }
        widgets = widgetDisplayUseCase.allVisibleWidgetTypes()
    }

    func togglePresentSheet() {
        tracker.trackAnalyticsEvent(with: HomeFabOptionsButtonPressedEvent())
        presentsSheet.toggle()
    }

    func trackHomeScreenAppear() {
        tracker.trackAnalyticsEvent(with: HomeScreenEvent())
    }

    func monitorNetworkConnection() async {
        isNetworkConnected = networkMonitoringUseCase.isConnected()
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
