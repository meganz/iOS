import ChatRepoMock
import Foundation
@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

class DownloadFileRepositoryTests: XCTestCase {
    
    func testDownloadNodeHandle_shouldUseNodeProvider() async throws {
        // Arrange
        let node = MockNode(handle: 1)
        let sdk = MockSdk(nodes: [node])
        let nodeProvider = MockMEGANodeProvider(node: node)
        let sut = makeSUT(sdk: sdk, nodeProvider: nodeProvider)
                
        // Act
        let result = try await sut.download(nodeHandle: node.handle, to: URL(fileURLWithPath: "/path"), metaData: .saveInPhotos)
        
        // Assert
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
        XCTAssertEqual(sdk.authorizeNodeCalled, 0)
        XCTAssertEqual(nodeProvider.nodeForHandleCallCount, 1)
        XCTAssertEqual(result.nodeHandle, node.handle)
    }
    
    func testDownloadNodeHandle_forFolderLinks_shouldUseCorrectFolderLinksSDK() async throws {
        // Arrange
        let node = MockNode(handle: 1)
        let sdk = MockSdk()
        let folderLinksSDK = MockSdk(nodes: [node])
        let nodeProvider = MockMEGANodeProvider()
        let sut = makeSUT(sdk: sdk, folderLinksSDK: folderLinksSDK, nodeProvider: nodeProvider)
                
        // Act
        let result = try await sut.download(nodeHandle: node.handle, to: URL(fileURLWithPath: "/path"), metaData: .saveInPhotos)
        
        // Assert
        XCTAssertEqual(sdk.nodeForHandleCallCount, 0)
        XCTAssertEqual(folderLinksSDK.nodeForHandleCallCount, 1)
        XCTAssertEqual(folderLinksSDK.authorizeNodeCalled, 1)
        XCTAssertEqual(nodeProvider.nodeForHandleCallCount, 0)
        XCTAssertEqual(result.nodeHandle, node.handle)
    }
    
    func makeSUT(sdk: MEGASdk = MockSdk(),
                 folderLinksSDK: MEGASdk? = nil,
                 nodeProvider: any MEGANodeProviderProtocol = MockMEGANodeProvider()) -> DownloadFileRepository {
        DownloadFileRepository(
            sdk: sdk,
            sharedFolderSdk: folderLinksSDK,
            nodeProvider: nodeProvider)
    }
}
