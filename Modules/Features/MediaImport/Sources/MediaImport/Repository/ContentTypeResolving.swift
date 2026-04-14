import Foundation
import UniformTypeIdentifiers

package protocol ContentTypeResolving: Sendable {
    func preferredContentType(for provider: NSItemProvider) -> UTType
}

package struct ContentTypeResolver: ContentTypeResolving {

    package init() {}

    /// Returns the most specific registered content type for the provider,
    /// preserving the original format (HEIC, PNG, JPEG, etc.).
    ///
    /// The provider may list types in a non-ideal order (e.g. `.jpeg` before `.heic`
    /// for a HEIF Live Photo). We prefer `.heic` when available since that's the
    /// original format — falling back to the first concrete image type otherwise.
    /// Skips `.livePhoto` and Apple-internal types.
    ///
    /// We use `isPublic` to filter out Apple-internal types
    /// (e.g. `com.apple.private.photos.thumbnail.standard`) that are not loadable
    /// as file data. Non-public image formats (e.g. `com.compuserve.gif`) are
    /// handled by the generic fallback.
    package func preferredContentType(for provider: NSItemProvider) -> UTType {
        let imageTypes = provider.registeredContentTypes(conformingTo: .image)

        let concreteImageTypes = imageTypes.filter { $0.isPublic && !$0.conforms(to: .livePhoto) }

        if let preferred = concreteImageTypes.first(where: { $0 == .heic }) ?? concreteImageTypes.first {
            return preferred
        } else if let movieType = provider.registeredContentTypes(conformingTo: .movie).first {
            return movieType
        } else {
            return provider.registeredContentTypes.first ?? .item
        }
    }
}
