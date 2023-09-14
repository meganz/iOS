import SwiftUI
import WebKit

struct AdsWebView: UIViewRepresentable {
    let url: URL?
    let adsTapAction: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.configuration.userContentController.addUserScript(disableZoomScript())
        webview.scrollView.isScrollEnabled = false
        webview.isOpaque = false
        webview.backgroundColor = .clear
        webview.scrollView.backgroundColor = .clear
        return webview
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
}
