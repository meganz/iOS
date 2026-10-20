import MEGAAppPresentation
import UIKit

public final class MockAppLauncher: URLOpening {
    public var canOpenURL_calledTimes = 0
    public var open_calledTimes = 0
    /// Returned by `canOpenURL`: `true` as if the app were installed, `false` as if it were not.
    public var canOpenURLResult: Bool
    /// Reported to every `open` completion; `false` also stands for the user cancelling the system prompt.
    public var openResult: Bool
    public var lastOpenedURL: URL?
    public var openedURLs: [URL] = []

    public init(canOpenURLResult: Bool, openResult: Bool = true) {
        self.canOpenURLResult = canOpenURLResult
        self.openResult = openResult
    }

    public func canOpenURL(_ url: URL) -> Bool {
        canOpenURL_calledTimes += 1
        return canOpenURLResult
    }

    public func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?) {
        open_calledTimes += 1
        lastOpenedURL = url
        openedURLs.append(url)
        completion?(openResult)
    }
}
