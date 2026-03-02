@testable import ContentLibraries
import MEGAAppSDKRepo
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeUseCaseFactoryTests: XCTestCase {
    
    func testMakeNodeUseCase_albumAndMediaLinkContentModes_shouldReturnNil() {
        [PhotoLibraryContentMode.albumLink, .mediaDiscoveryFolderLink].enumerated().forEach {
            let nodeUseCase = NodeUseCaseFactory.makeNodeUseCase(
                for: $1,
                configuration: .mockConfiguration())
            
            XCTAssertNil(nodeUseCase, "Failed at index: \($0) for value: \($1)")
        }
    }
    
    func testMakeNodeUseCase_nonLinkContentModes_shouldReturnNodeUseCase() {
        [PhotoLibraryContentMode.library, .album, .mediaDiscovery].enumerated().forEach {
            let nodeUseCase = NodeUseCaseFactory.makeNodeUseCase(
                for: $1,
                configuration: .mockConfiguration())
             
            XCTAssertTrue(nodeUseCase is MockNodeUseCase, "Failed at index: \($0) for value: \($1)")
         }
    }
}
