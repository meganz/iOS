import Foundation

public enum ViewedLinksFactory {
    private static let sharedStore: any ViewedLinksStoreProtocol = ViewedLinksStore()

    /// A use case over the shared store, for the app / Presentation layer.
    public static func makeViewedLinksUseCase() -> some ViewedLinksUseCaseProtocol {
        ViewedLinksUseCase(repository: makeViewedLinkRepository())
    }

    static func makeViewedLinkThumbnailUseCase() -> some ViewedLinkThumbnailUseCaseProtocol {
        ViewedLinkThumbnailUseCase(repository: ViewedLinkThumbnailRepository())
    }

    private static func makeViewedLinkRepository() -> some ViewedLinksRepositoryProtocol {
        ViewedLinksRepository(store: sharedStore)
    }
}
