@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGASDKRepo
import XCTest

final class NodeUseCaseFactoryTests: XCTestCase {

    func testMakeNodeUseCase_hiddenNodesOff_shouldReturnNil() {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let nodeUseCase = NodeUseCaseFactory.makeNodeUseCase(for: .library, featureFlagProvider: featureFlagProvider)
        
        XCTAssertNil(nodeUseCase)
    }
    
    func testMakeNodeUseCase_albumAndMediaLinkContentModes_shouldReturnNil() {
        [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink].enumerated().forEach {
             let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
             let nodeUseCase = NodeUseCaseFactory.makeNodeUseCase(for: $1,
                                                                  featureFlagProvider: featureFlagProvider)
             
             XCTAssertNil(nodeUseCase, "Failed at index: \($0) for value: \($1)")
         }
    }
    
    func testMakeNodeUseCase_nonLinkContentModes_shouldReturnNodeUseCase() {
        [PhotoLibraryContentMode.library, .album, .mediaDiscovery].enumerated().forEach {
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let nodeUseCase = NodeUseCaseFactory.makeNodeUseCase(for: $1,
                                                                 featureFlagProvider: featureFlagProvider)
             
             XCTAssertTrue(nodeUseCase is NodeUseCase<NodeDataRepository, NodeValidationRepository, NodeRepository>,
                           "Failed at index: \($0) for value: \($1)")
         }
    }
}
