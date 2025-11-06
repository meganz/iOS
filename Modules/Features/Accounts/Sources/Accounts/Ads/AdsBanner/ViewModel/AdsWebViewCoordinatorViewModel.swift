import WebKit

@MainActor
struct AdsWebViewCoordinatorViewModel {
    func shouldHandleAdsTap(
        currentDomain: String,
        targetDomain: String,
        navigationAction: WKNavigationAction
    ) -> Bool {
        
        guard navigationAction.navigationType != .linkActivated else {
            return true
        }
        
        guard currentDomain != targetDomain else {
            return false
        }
        
        guard let targetFrame = navigationAction.targetFrame else {
            return true
        }
        
        return !navigationAction.sourceFrame.isMainFrame && targetFrame.isMainFrame
    }

    func urlHost(url: URL?) -> String? {
        url?.host
    }
}
