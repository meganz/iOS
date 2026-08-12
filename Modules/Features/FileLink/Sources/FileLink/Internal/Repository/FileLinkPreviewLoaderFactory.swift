import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

/// Builds the loader the file link screen uses for its preview.
///
/// `ThumbnailRepository` already knows how to cache and download previews; the only thing it lacks
/// for a public link is a way to reach the node, which `nodeProvider` supplies. Nothing else needs
/// to be written, so the file link keeps sharing the cache with the rest of the app.
///
/// No session is needed: the request carries the node, so this works for a link opened while logged
/// out. It does have to be the same `MEGASdk` instance the link was resolved on, `sharedSdk`, which
/// is why the instance is named here rather than injected.
enum FileLinkPreviewLoaderFactory {
    static func makePreviewLoader(nodeProvider: FileLinkNodeProvider) -> any ThumbnailLoaderProtocol {
        ThumbnailLoaderFactory.makeThumbnailLoader(
            config: .general,
            thumbnailUseCase: ThumbnailUseCase(
                repository: ThumbnailRepository(
                    sdk: .sharedSdk,
                    fileManager: .default,
                    nodeProvider: nodeProvider
                )
            )
        )
    }
}
