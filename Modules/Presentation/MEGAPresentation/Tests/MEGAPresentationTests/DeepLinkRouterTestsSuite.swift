@testable import MEGAPresentation
import MEGAPresentationMock
import Testing

@Suite("Deep Link Router Tests - Verifies app and App Store opening behavior based on deep links and in-app navigation.")
struct DeepLinkRouterTestSuite {
    
    // MARK: - Helpers
    @MainActor
    private static func makeSUTForExternalNavigation(
        canOpenURLResult: Bool,
        app: MEGAApp
    ) -> (router: DeepLinkRouter, mockAppLauncher: MockAppLauncher) {
        let mockAppLauncher = MockAppLauncher(canOpenURLResult: canOpenURLResult)
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
    private static func assertAppOpened(
        router: DeepLinkRouter,
        app: MEGAApp,
        expectedURL: String?,
        appLauncher: MockAppLauncher
    ) {
        router.openApp()
        if let expectedURL = expectedURL {
            #expect(appLauncher.open_calledTimes == 1, "Expected the app to open once.")
            #expect(appLauncher.lastOpenedURL?.absoluteString == expectedURL, "Expected URL to be \(expectedURL), but got \(String(describing: appLauncher.lastOpenedURL?.absoluteString)).")
        } else {
            #expect(appLauncher.open_calledTimes == 0, "Expected the app to not open.")
        }
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
            
            assertAppOpened(
                router: router,
                app: app,
                expectedURL: app.scheme,
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
            
            assertAppOpened(
                router: router,
                app: app,
                expectedURL: app.appStoreURL,
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
