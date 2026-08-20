@testable import Home
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
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

    /// The dispatcher's own behaviour — the folder short circuit, the in-flight de-duplication,
    /// the snack bar on a blocked file — belongs to `OfflineAwareNodeTapDispatcherTests`. What is
    /// only true here is that the view model builds it around the guard it was handed, which a
    /// blocked tap is enough to show.
    @Test("routes taps through a dispatcher built around the guard it was given")
    func offlineNodeTapDispatcherUsesTheInjectedGuard() async {
        let sut = makeSUT(offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: true, shouldBlock: true))
        var blockedTapWasReported = false
        var openCount = 0
        sut.offlineNodeTapDispatcher.showFileUnavailableSnackBar = { blockedTapWasReported = true }

        sut.offlineNodeTapDispatcher.dispatch(nodeHandle: 1, isFolder: false) { _ in openCount += 1 }

        await waitUntil { blockedTapWasReported }
        #expect(openCount == 0)
    }

    /// Each screen gets its own, so that the screen presenting the snack bar is the one the tap
    /// happened on — sharing one would report a pushed screen's blocked tap on the root beneath it.
    @Test("hands out a separate dispatcher per screen")
    func makesOneDispatcherPerScreen() {
        let sut = makeSUT()

        #expect(sut.makeOfflineNodeTapDispatcher() !== sut.makeOfflineNodeTapDispatcher())
        #expect(sut.makeOfflineNodeTapDispatcher() !== sut.offlineNodeTapDispatcher)
    }

    @Test("builds the dispatchers it hands out around the guard it was given")
    func handedOutDispatcherUsesTheInjectedGuard() async {
        let sut = makeSUT(offlineFileOpenGuard: MockOfflineFileOpenGuard(isActive: true, shouldBlock: true))
        let dispatcher = sut.makeOfflineNodeTapDispatcher()
        var blockedTapWasReported = false
        var openCount = 0
        dispatcher.showFileUnavailableSnackBar = { blockedTapWasReported = true }

        dispatcher.dispatch(nodeHandle: 1, isFolder: false) { _ in openCount += 1 }

        await waitUntil { blockedTapWasReported }
        #expect(openCount == 0)
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
    isConnected: Bool = true,
    offlineFileOpenGuard: MockOfflineFileOpenGuard = MockOfflineFileOpenGuard(isActive: false)
) -> HomeViewModel {
    HomeViewModel(
        homeDeepLink: HomeDeepLink(),
        networkMonitoringUseCase: MockNetworkMonitorUseCase(connected: isConnected),
        widgetDisplayUseCase: HomeWidgetDisplayUseCase(preferenceUseCase: MockPreferenceUseCase()),
        tracker: MockTracker(),
        featureFlagProvider: MockFeatureFlagProvider(list: [.offlineMode: isNewOfflineModeEnabled]),
        nodeUseCase: MockNodeDataUseCase(nodes: [NodeEntity(name: "report.pdf", handle: 1, isFile: true)]),
        offlineFileOpenGuard: offlineFileOpenGuard
    )
}

/// Yields the main actor until `condition` holds, so the guard's asynchronous check — and only it —
/// gets to run. Bounded, so a regression fails on the assertion that follows instead of hanging.
@MainActor
private func waitUntil(iterations: Int = 1_000, _ condition: () -> Bool) async {
    for _ in 0..<iterations {
        if condition() { return }
        await Task.yield()
    }
}
