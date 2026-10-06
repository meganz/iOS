@testable import MEGAAppPresentation
import MEGAAppPresentationMock
import Testing

@Suite("Deep Link Router Tests - Verifies app and App Store opening behavior based on deep links and in-app navigation.")
struct DeepLinkRouterTestSuite {
    
    // MARK: - Helpers
    @MainActor
    private static func makeSUTForExternalNavigation(
        openResult: Bool,
        app: MEGAApp
    ) -> (router: DeepLinkRouter, mockAppLauncher: MockAppLauncher) {
        let mockAppLauncher = MockAppLauncher(openResult: openResult)
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
                openResult: true,
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
                openResult: false,
                app: app
            )
            
            // The app scheme is tried first; the system reports it could not be opened, so the App Store follows.
            assertOpenedURLs(
                router: router,
                expectedURLs: [app.scheme, app.appStoreURL],
                appLauncher: mockAppLauncher
            )
        }
    }
    
    // MARK: - In-App Navigation Tests
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
