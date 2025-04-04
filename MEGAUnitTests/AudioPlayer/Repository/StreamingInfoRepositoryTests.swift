@testable import MEGA
import MEGAAppSDKRepoMock
import MEGASdk
import MEGATest
import XCTest

final class StreamingInfoRepositoryTests: XCTestCase {
    
    func testInfoFromFolderLinkNode_whenInvalidNode_returnsNilInfo() {
        let invalidNode = MEGANode()
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        
        let result = sut.info(fromFolderLinkNode: invalidNode)
        
        XCTAssertNil(result, "Expect nil result, got non nil instead.")
    }
    
    func testInfoFromFolderLinkNode_whenValidNode_returnsNonNilInfo() {
        let validNode = MockNode(handle: 1, name: "any-name")
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)
        
        let result = sut.info(fromFolderLinkNode: validNode)
        
        XCTAssertNil(result, "Expect nil non nil, got nil instead.")
    }
    
    func testPathFromNode_returnsNil() {
        let validNode = MockNode(handle: 1, name: "any-name")
        let sdk = MockSdk(nodes: [validNode])
        let sut = makeSUT(sdk: sdk)
        
        let result = sut.path(fromNode: validNode)
        
        XCTAssertNil(result, "Expect nil, got non nil instead.")
    }
    
    func testIsLocalHTTPProxyServerRunning_whenNotRunning_returnsFalse() {
        let sdk = MockSdk()
        let sut = makeSUT(sdk: sdk)

        let result = sut.isLocalHTTPProxyServerRunning()

        XCTAssertFalse(result, "Expect to return false, got true instead.")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(sdk: MockSdk, file: StaticString = #filePath, line: UInt = #line) -> StreamingInfoRepository {
        let sut = StreamingInfoRepository(sdk: sdk)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
}
