import UIKit

public protocol URLOpening {
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?)
}

extension UIApplication: URLOpening {}

@MainActor
protocol DeepLinkRoutable {
    func openApp(for app: MEGAApp)
}

public struct DeepLinkRouter: DeepLinkRoutable {
    private let appOpener: any URLOpening
    private let logHandler: (String) -> Void
    
    public init(
        appOpener: some URLOpening = UIApplication.shared,
        logHandler: @escaping (String) -> Void
    ) {
        self.appOpener = appOpener
        self.logHandler = logHandler
    }
    
    public func openApp(for app: MEGAApp) {
        if let appURL = URL(string: app.scheme), appOpener.canOpenURL(appURL) {
            appOpener.open(appURL, options: [:], completionHandler: nil)
        } else if let appStoreURL = URL(string: app.appStoreURL) {
            appOpener.open(appStoreURL, options: [:], completionHandler: nil)
        } else {
            logHandler("[DeepLink] Both app scheme and App Store URLs are unavailable for \(app).")
        }
    }
}
