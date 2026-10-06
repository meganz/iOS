import MEGAAppPresentation
import UIKit

public final class MockAppLauncher: URLOpening {
    public var open_calledTimes = 0
    /// Reported to every `open` completion: `true` as if the app were installed, `false` as if it were not.
    public var openResult: Bool
    public var lastOpenedURL: URL?
    public var openedURLs: [URL] = []

    public init(openResult: Bool) {
        self.openResult = openResult
    }

    public func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?) {
        open_calledTimes += 1
        lastOpenedURL = url
        openedURLs.append(url)
        completion?(openResult)
    }
}
