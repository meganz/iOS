@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

@Suite("Deep Link Router Tests - Verifies app and App Store opening behavior based on deep links and in-app navigation.")
struct DeepLinkRouterTestSuite {
    
    // MARK: - Helpers
    @MainActor
    private static func makeSUTForExternalNavigation(
        canOpenURLResult: Bool,
        openResult: Bool = true,
        app: MEGAApp
    ) -> (router: DeepLinkRouter, mockAppLauncher: MockAppLauncher) {
        let mockAppLauncher = MockAppLauncher(canOpenURLResult: canOpenURLResult, openResult: openResult)
        let appOpener = AppOpener(
            opener: mockAppLauncher,
            app: app
        )
        let router = DeepLinkRouter(appOpener: appOpener)
        return (router, mockAppLauncher)
    }
    
    @MainActor
    private static func makeSUTForInternalNavigation() -> (router: DeepLinkRouter, mockNavigator: MockNavigator) {
        let mockNavigator = MockNavigator()
        let router = DeepLinkRouter(appNavigator: mockNavigator)
        return (router, mockNavigator)
    }
    
    @MainActor
    private static func assertOpenedURLs(
        router: DeepLinkRouter,
        expectedURLs: [String],
        appLauncher: MockAppLauncher
    ) {
        router.openApp()
        #expect(appLauncher.openedURLs.map(\.absoluteString) == expectedURLs, "Expected \(expectedURLs) to be opened in order, but got \(appLauncher.openedURLs.map(\.absoluteString)).")
        #expect(appLauncher.canOpenURL_calledTimes == 1, "Expected canOpenURL to be called once.")
    }
    
    // MARK: - App Link Tests
    @Suite("App Link Tests - Verifies behavior when opening the selected app through a deep link.")
    struct VPNLinkTests {
        
        @MainActor
        @Test("App scheme should open the app if installed", arguments: [
            MEGAApp.vpn,
            MEGAApp.pwm
        ])
        func vpnLinkShouldOpenVPNAppIfInstalled(app: MEGAApp) {
            let (router, mockAppLauncher) = makeSUTForExternalNavigation(
                canOpenURLResult: true,
                app: app
            )
            
            assertOpenedURLs(
                router: router,
                expectedURLs: [app.scheme],
                appLauncher: mockAppLauncher
            )
        }
        
        @MainActor
        @Test("Cancelling the system prompt to open an installed app should not open the App Store", arguments: [
            MEGAApp.vpn,
            MEGAApp.pwm
        ])
        func cancelledOpenOfInstalledAppShouldNotOpenAppStore(app: MEGAApp) {
            // The open reports `false` when the user cancels the "Open in …?" prompt.
            let (router, mockAppLauncher) = makeSUTForExternalNavigation(
                canOpenURLResult: true,
                openResult: false,
                app: app
            )
            
            assertOpenedURLs(
                router: router,
                expectedURLs: [app.scheme],
                appLauncher: mockAppLauncher
            )
        }
        
        @MainActor
        @Test("App scheme should open the App Store if the selected app is not installed", arguments: [
            MEGAApp.vpn,
            MEGAApp.pwm
        ])
        func vpnLinkShouldOpenAppStoreIfAppNotInstalled(app: MEGAApp) {
            let (router, mockAppLauncher) = makeSUTForExternalNavigation(
                canOpenURLResult: false,
                app: app
            )
            
            assertOpenedURLs(
                router: router,
                expectedURLs: [app.appStoreURL],
                appLauncher: mockAppLauncher
            )
        }
    }
    
    // MARK: - In-App Navigation Tests
    @Suite("Logging Tests - Verifies what is logged when the app is not opened.")
    struct LoggingTests {
        @MainActor
        @Test("Logs only when the app is not installed or not opened", arguments: [
            (canOpenURLResult: true, openResult: true, expectedLog: nil),
            (canOpenURLResult: true, openResult: false, expectedLog: "was not opened: cancelled by the user or failed"),
            (canOpenURLResult: false, openResult: true, expectedLog: "is not installed according to canOpenURL")
        ])
        func logsWhenAppIsNotOpened(canOpenURLResult: Bool, openResult: Bool, expectedLog: String?) {
            var logs: [String] = []
            let appOpener = AppOpener(
                opener: MockAppLauncher(canOpenURLResult: canOpenURLResult, openResult: openResult),
                app: .vpn,
                logHandler: { logs.append($0) }
            )

            appOpener.openApp()

            if let expectedLog {
                #expect(logs.count == 1)
                #expect(logs.first?.contains(expectedLog) == true)
            } else {
                #expect(logs.isEmpty)
            }
        }
    }

    @Suite("In-App Navigation Tests - Verifies behavior for internal navigation within the app.")
    struct InAppNavigationTests {
        
        @MainActor
        @Test("Should navigate within the app if the navigator is provided")
        func shouldNavigateWithinApp() {
            let (router, mockNavigator) = makeSUTForInternalNavigation()
            
            router.navigate()
            
            #expect(mockNavigator.start_calledTimes == 1, "Expected the in-app navigation to be triggered once.")
        }
    }
}
