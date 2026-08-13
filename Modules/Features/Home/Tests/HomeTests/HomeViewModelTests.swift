@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomainMock
import MEGAPreferenceMocks
import Testing

@Suite("HomeViewModelTests Tests")
@MainActor
struct HomeViewModelTests {

    @Suite("New offline mode")
    @MainActor
    struct NewOfflineMode {
        @Test("is on when the offline mode feature flag is enabled")
        func enabledFlag() {
            let sut = makeSUT(isNewOfflineModeEnabled: true)

            #expect(sut.isNewOfflineModeEnabled)
        }

        @Test("is off when the offline mode feature flag is disabled, keeping the full-page cover")
        func disabledFlag() {
            let sut = makeSUT(isNewOfflineModeEnabled: false)

            #expect(!sut.isNewOfflineModeEnabled)
        }

        /// The page swaps between the banner and the full-page cover on this value, so it has to be
        /// read once at init — a mid-session read would tear the widgets down when the flag is
        /// toggled in the developer settings.
        @Test("stays as it was at init, offline as well as online")
        func doesNotDependOnConnectivity() {
            let sut = makeSUT(isNewOfflineModeEnabled: true, isConnected: false)

            #expect(sut.isNewOfflineModeEnabled)
        }
    }

    @Test("reports the connection state it starts with")
    func initialConnectionState() {
        #expect(makeSUT(isConnected: true).isNetworkConnected)
        #expect(!makeSUT(isConnected: false).isNetworkConnected)
    }
}

@MainActor
private func makeSUT(
    isNewOfflineModeEnabled: Bool = false,
    isConnected: Bool = true
) -> HomeViewModel {
    HomeViewModel(
        homeDeepLink: HomeDeepLink(),
        networkMonitoringUseCase: MockNetworkMonitorUseCase(connected: isConnected),
        widgetDisplayUseCase: HomeWidgetDisplayUseCase(preferenceUseCase: MockPreferenceUseCase()),
        tracker: MockTracker(),
        featureFlagProvider: MockFeatureFlagProvider(list: [.offlineMode: isNewOfflineModeEnabled])
    )
}
