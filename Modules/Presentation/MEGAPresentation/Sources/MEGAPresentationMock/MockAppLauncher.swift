import MEGAPresentation
import UIKit

public final class MockAppLauncher: URLOpening {
    public var canOpenURL_calledTimes = 0
    public var open_calledTimes = 0
    public var canOpenURLResult: Bool
    public var lastOpenedURL: URL?

    public init(canOpenURLResult: Bool) {
        self.canOpenURLResult = canOpenURLResult
    }

    public func canOpenURL(_ url: URL) -> Bool {
        canOpenURL_calledTimes += 1
        return canOpenURLResult
    }

    public func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: (@MainActor @Sendable (Bool) -> Void)?) {
        open_calledTimes += 1
        lastOpenedURL = url
    }
}
