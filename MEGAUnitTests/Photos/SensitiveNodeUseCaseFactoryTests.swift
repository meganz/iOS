@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import Testing

struct SensitiveNodeUseCaseFactoryTests {

    @Suite("Hidden Nodes Off")
    struct FeatureFlagOff {
        @Test("Feature flag off should return nil",
              arguments: PhotoLibraryContentMode.allCases)
        func featureFlagOff(mode: PhotoLibraryContentMode) {
            let useCase = SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(
                for: mode,
                featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: false]))
            
            #expect(useCase == nil)
        }
    }
    
    @Suite("Valid Modes")
    struct ValidModes {
        @Test("Modes library, album and media discovery should return use case",
              arguments: [PhotoLibraryContentMode.library, .album, .mediaDiscovery])
        func validModes(mode: PhotoLibraryContentMode) {
            let useCase = SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(
                for: mode,
                featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
            
            #expect(useCase != nil)
        }
    }
    
    @Suite("Invalid Modes")
    struct InvalidModes {
        @Test("Modes library, album and media discovery should return use case",
              arguments: [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink])
        func validModes(mode: PhotoLibraryContentMode) {
            let useCase = SensitiveNodeUseCaseFactory.makeSensitiveNodeUseCase(
                for: mode,
                featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]))
            
            #expect(useCase == nil)
        }
    }
}

extension PhotoLibraryContentMode {
    static var allCases: [PhotoLibraryContentMode] = [
        .library,
        .album,
        .albumLink,
        .mediaDiscovery,
        .mediaDiscoveryFolderLink
    ]
}
