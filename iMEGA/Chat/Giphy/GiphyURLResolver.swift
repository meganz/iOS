import Foundation

/// Turns the source string carried inside a Giphy chat message into a URL the app may fetch.
///
/// The source is authored by whoever sent the message, so it is only trusted when it points at MEGA's
/// Giphy proxy: either the `giphy://` shorthand the app writes when sending, or an absolute proxy URL.
/// Anything else resolves to `nil` and must not be loaded, otherwise a chat peer could make the
/// recipient's device request an arbitrary host the moment the message is rendered.
enum GiphyURLResolver {
    static func webURL(from source: String?) -> URL? {
        guard let source else { return nil }
        let proxyBase = ServiceManager.shared.BASE_URL
        let shorthand = ServiceManager.shared.GIPHY_URL

        let absolute: String
        if source.hasPrefix(shorthand) {
            absolute = proxyBase + source.dropFirst(shorthand.count)
        } else if source.hasPrefix(proxyBase) {
            absolute = source
        } else {
            return nil
        }

        guard let proxy = URLComponents(string: proxyBase),
              let resolved = URLComponents(string: absolute),
              resolved.scheme == proxy.scheme,
              resolved.host == proxy.host,
              let url = resolved.url else {
            return nil
        }
        return url
    }
}
