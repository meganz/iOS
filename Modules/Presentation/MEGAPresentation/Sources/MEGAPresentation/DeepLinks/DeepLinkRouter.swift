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
    
    /// Attempts to open the external app or its App Store page.
    public func openApp() {
        if let appURL = URL(string: app.scheme), opener.canOpenURL(appURL) {
            opener.open(appURL, options: [:], completionHandler: nil)
        } else if let appStoreURL = URL(string: app.appStoreURL) {
            opener.open(appStoreURL, options: [:], completionHandler: nil)
        } else {
            logHandler?("[DeepLink] Unable to open app or App Store for \(app).")
        }
    }
}

public struct DeepLinkRouter: DeepLinkRoutable {
    private let appNavigator: Routing?
    private let appOpener: AppOpener?
    
    /// Initializes the DeepLinkRouter with handlers for internal and external navigation.
    /// - Parameters:
    ///   - appNavigator: Handles internal app navigation.
    ///   - appOpener: Handles external app navigation.
    public init(
        appNavigator: Routing? = nil,
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
