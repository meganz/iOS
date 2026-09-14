import Foundation

/// Composition root for the Viewed Links module.
///
/// Vends a use case backed by a single, process-wide shared store so every
/// reader and the recorder observe the same data. The store is created lazily
/// on first access.
public enum ViewedLinksFactory {
    private static let sharedStore: any ViewedLinksStoreProtocol = ViewedLinksStore()

    /// A use case over the shared store, for the app / Presentation layer.
    public static func makeUseCase() -> some ViewedLinksUseCaseProtocol {
        ViewedLinksUseCase(repository: makeRepository())
    }

    private static func makeRepository() -> some ViewedLinksRepositoryProtocol {
        ViewedLinksRepository(store: sharedStore)
    }
}
