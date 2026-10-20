import UIKit

@MainActor
public protocol URLOpening {
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?)
}

extension UIApplication: URLOpening {}

@MainActor
protocol DeepLinkRoutable {
    func openApp()
    func navigate()
}

@MainActor
public struct AppOpener {
    private let opener: any URLOpening
    private let app: MEGAApp
    private let logHandler: ((String) -> Void)?
    
    /// Initializes the AppOpener.
    /// - Parameters:
    ///   - opener: Handles opening external URLs.
    ///   - app: The MEGAApp to open.
    ///   - log: Optional handler to log errors or status messages.
    public init(
        opener: some URLOpening = UIApplication.shared,
        app: MEGAApp,
        logHandler: ((String) -> Void)? = nil
    ) {
        self.opener = opener
        self.app = app
        self.logHandler = logHandler
    }
    
    /// Opens the external app, or its App Store page when the app is not installed.
    ///
    /// Whether the app is installed is checked with `canOpenURL` before opening it. The result of the open
    /// can't tell that apart: it is also `false` when the user cancels the system's "Open in …?" prompt,
    /// which must not lead to the App Store.
    public func openApp() {
        guard let appURL = URL(string: app.scheme), opener.canOpenURL(appURL) else {
            // Also reached when the scheme is missing from `LSApplicationQueriesSchemes`
            logHandler?("[DeepLink] \(app) is not installed according to canOpenURL, opening the App Store")
            openAppStore()
            return
        }
        opener.open(appURL, options: [:]) { [logHandler, app] opened in
            guard !opened else { return }
            logHandler?("[DeepLink] \(appURL) for \(app) was not opened: cancelled by the user or failed")
        }
    }

    private func openAppStore() {
        guard let appStoreURL = URL(string: app.appStoreURL) else {
            logHandler?("[DeepLink] Unable to open app or App Store for \(app).")
            return
        }
        opener.open(appStoreURL, options: [:], completionHandler: nil)
    }
}

public struct DeepLinkRouter: DeepLinkRoutable {
    private let appNavigator: (any Routing)?
    private let appOpener: AppOpener?
    
    /// Initializes the DeepLinkRouter with handlers for internal and external navigation.
    /// - Parameters:
    ///   - appNavigator: Handles internal app navigation.
    ///   - appOpener: Handles external app navigation.
    public init(
        appNavigator: (any Routing)? = nil,
        appOpener: AppOpener? = nil
    ) {
        self.appNavigator = appNavigator
        self.appOpener = appOpener
    }
    
    /// Opens the external app or App Store URL.
    public func openApp() {
        appOpener?.openApp()
    }
    
    /// Navigates within the app.
    public func navigate() {
        appNavigator?.start()
    }
}
