@testable import MEGAPresentation
import MEGAPresentationMock
import Testing

@Suite("Deep Link Router Tests - Verifies app and App Store opening behavior based on deep links.")
struct DeepLinkRouterTestSuite {
    
    // MARK: - Helpers
    @MainActor
    private static func makeSUT(
        canOpenURLResult: Bool,
        app: MEGAApp
    ) -> (router: DeepLinkRouter, mockAppLauncher: MockAppLauncher) {
        let mockAppLauncher = MockAppLauncher(canOpenURLResult: canOpenURLResult)
        let router = DeepLinkRouter(appOpener: mockAppLauncher, logHandler: {_ in })
        return (router, mockAppLauncher)
    }

    @MainActor
    private static func assertAppOpened(
        router: DeepLinkRouter,
        app: MEGAApp,
        expectedURL: String?,
        appLauncher: MockAppLauncher
    ) {
        router.openApp(for: app)
        if let expectedURL = expectedURL {
            #expect(appLauncher.open_calledTimes == 1, "Expected the app to open once.")
            #expect(appLauncher.lastOpenedURL?.absoluteString == expectedURL, "Expected URL to be \(expectedURL), but got \(String(describing: appLauncher.lastOpenedURL?.absoluteString)).")
        } else {
            #expect(appLauncher.open_calledTimes == 0, "Expected the app to not open.")
        }
    }
    
    // MARK: - App Link Tests
    @Suite("App Link Tests - Verifies behavior when opening the selected app through a deep link.")
    struct VPNLinkTests {
        @MainActor
        @Test("App scheme should open the app if installed", arguments: [
            MEGAApp.vpn
        ])
        func vpnLinkShouldOpenVPNAppIfInstalled(app: MEGAApp) {
            let (router, mockAppLauncher) = makeSUT(
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
            MEGAApp.vpn
        ])
        func vpnLinkShouldOpenAppStoreIfAppNotInstalled(app: MEGAApp) {
            let (router, mockAppLauncher) = makeSUT(
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
}
