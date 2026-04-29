import WebKit

@MainActor
struct AdsWebViewCoordinatorViewModel {
    func shouldHandleAdsTap(
        currentDomain: String,
        targetDomain: String,
        navigationType: WKNavigationType,
        sourceIsMainFrame: Bool,
        targetIsMainFrame: Bool?
    ) -> Bool {

        guard navigationType != .linkActivated else {
            return true
        }

        guard currentDomain != targetDomain else {
            return false
        }

        guard let targetIsMainFrame else {
            return true
        }

        return !sourceIsMainFrame && targetIsMainFrame
    }

    func urlHost(url: URL?) -> String? {
        url?.host
    }
}
