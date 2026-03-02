import MEGADomain

public struct NodeUseCaseFactory {
    public static func makeNodeUseCase(
        for mode: PhotoLibraryContentMode,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) -> (any NodeUseCaseProtocol)? {
        guard [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return configuration.nodeUseCase
    }
}
