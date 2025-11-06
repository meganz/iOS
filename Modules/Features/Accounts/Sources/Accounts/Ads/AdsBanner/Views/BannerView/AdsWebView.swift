import SwiftUI
import WebKit

struct AdsWebView: UIViewRepresentable {
    let url: URL?
    let coordinatorViewModel: AdsWebViewCoordinatorViewModel
    let adsTapAction: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator
        webview.configuration.userContentController.addUserScript(disableZoomScript())
        webview.scrollView.isScrollEnabled = false
        webview.isOpaque = false
        webview.backgroundColor = .clear
        webview.scrollView.backgroundColor = .clear
        return webview
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, viewModel: coordinatorViewModel)
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func disableZoomScript() -> WKUserScript {
        // This will display the ads fully based on the container size and
        // disable zoom and double tap gesture
        let source = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    // MARK: - Coordinator
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let adsWebView: AdsWebView
        private let viewModel: AdsWebViewCoordinatorViewModel
        
        init(_ adsWebView: AdsWebView, viewModel: AdsWebViewCoordinatorViewModel) {
            self.adsWebView = adsWebView
            self.viewModel = viewModel
        }
        
        // MARK: WKUIDelegate
        
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url,
                  let currentDomain = viewModel.urlHost(url: webView.url),
                  let targetDomain = viewModel.urlHost(url: url),
                  viewModel.shouldHandleAdsTap(currentDomain: currentDomain,
                                               targetDomain: targetDomain,
                                               navigationAction: navigationAction) else {
                return nil
            }
            
            UIApplication.shared.open(url)
            adsWebView.adsTapAction()
            return nil
        }
        
        // MARK: WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  let currentDomain = viewModel.urlHost(url: webView.url),
                  let targetDomain = viewModel.urlHost(url: url) else {
                return .cancel
            }
            
            guard viewModel.shouldHandleAdsTap(
                currentDomain: currentDomain,
                targetDomain: targetDomain,
                navigationAction: navigationAction) else {
                return .allow
            }
            
            guard UIApplication.shared.canOpenURL(url) else {
                return .cancel
            }
            
            await MainActor.run { UIApplication.shared.open(url) }
            adsWebView.adsTapAction()
            
            return .cancel
        }
    }
}
