import MEGADomain

public struct SensitiveNodeUseCaseFactory {
    public static func makeSensitiveNodeUseCase(
        for mode: PhotoLibraryContentMode,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) -> (any SensitiveNodeUseCaseProtocol)? {
        guard [PhotoLibraryContentMode.library, .album, .mediaDiscovery].contains(mode) else {
            return nil
        }
        return configuration.sensitiveNodeUseCase
    }
}
