import XCTest
@testable import MEGA

final class NodeInfoUseCaseTests: XCTestCase {
    let nodeInfoSuccessRepository = MockNodeInfoRepository(result: .success(()))
    let nodeInfoFailureRepository = MockNodeInfoRepository(result: .failure(.generic))
    
    func testGetNodeFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.node(fromHandle: MEGAHandle()))
        XCTAssertNil(nodeInfoFailureRepository.node(fromHandle: MEGAHandle()))
    }
    
    func testGetFolderAuthNodeFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.folderNode(fromHandle: MEGAHandle()))
        XCTAssertNil(nodeInfoFailureRepository.folderNode(fromHandle: MEGAHandle()))
    }
    
    func testGetPathFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.path(fromHandle: MEGAHandle()))
        XCTAssertNil(nodeInfoFailureRepository.path(fromHandle: MEGAHandle()))
    }
    
    func testGetParentChildren() throws {
        let childrenArray = try XCTUnwrap(nodeInfoSuccessRepository.childrenInfo(fromParentHandle: MEGAHandle()))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(childrenArray.compactMap{$0.url}, mockArray.compactMap{$0.url})
        XCTAssertNil(nodeInfoFailureRepository.childrenInfo(fromParentHandle: MEGAHandle()))
    }
    
    func testGetFolderParentChildren() throws {
        let folderChildrenArray = try XCTUnwrap(nodeInfoSuccessRepository.folderChildrenInfo(fromParentHandle: MEGAHandle()))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(folderChildrenArray.compactMap{$0.url}, mockArray.compactMap{$0.url})
        XCTAssertNil(nodeInfoFailureRepository.folderChildrenInfo(fromParentHandle: MEGAHandle()))
    }
    
    func testGetInfoFromNode() throws {
        let nodeInfoArray = try XCTUnwrap(nodeInfoSuccessRepository.info(fromNodes: [MEGANode()]))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(nodeInfoArray.compactMap{$0.url}, mockArray.compactMap{$0.url})
        XCTAssertNil(nodeInfoFailureRepository.info(fromNodes: [MEGANode()]))
    }
    
    func testGetPublicNodeFromFileLink() {
        let expectations = expectation(description: "for async calls")
        
        nodeInfoSuccessRepository.publicNode(fromFileLink: "") { [weak self] node in
            XCTAssertNotNil(node)
            self?.nodeInfoFailureRepository.publicNode(fromFileLink: "") { node in
                XCTAssertNil(node)
                expectations.fulfill()
            }
        }
        
        wait(for: [expectations], timeout: 0.2)
    }
}
