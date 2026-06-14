import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsMagnification = true
        webView.allowsLinkPreview = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}
