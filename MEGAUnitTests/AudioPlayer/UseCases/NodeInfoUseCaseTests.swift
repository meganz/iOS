@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeInfoUseCaseTests: XCTestCase {
    let nodeInfoSuccessRepository = MockNodeInfoRepository(result: .success, violatesTermsOfServiceResult: .success(true))
    let nodeInfoFailureRepository = MockNodeInfoRepository(result: .failure(.generic), violatesTermsOfServiceResult: .success(true))
    
    func testGetNodeFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.node(fromHandle: HandleEntity()))
        XCTAssertNil(nodeInfoFailureRepository.node(fromHandle: HandleEntity()))
    }
    
    func testGetFolderAuthNodeFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.folderNode(fromHandle: HandleEntity()))
        XCTAssertNil(nodeInfoFailureRepository.folderNode(fromHandle: HandleEntity()))
    }
    
    func testGetPathFromHandle() {
        XCTAssertNotNil(nodeInfoSuccessRepository.path(fromHandle: HandleEntity()))
        XCTAssertNil(nodeInfoFailureRepository.path(fromHandle: HandleEntity()))
    }
    
    func testGetParentChildren() throws {
        let childrenArray = try XCTUnwrap(nodeInfoSuccessRepository.childrenInfo(fromParentHandle: HandleEntity()))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(childrenArray.compactMap {$0.url}, mockArray.compactMap {$0.url})
        XCTAssertNil(nodeInfoFailureRepository.childrenInfo(fromParentHandle: HandleEntity()))
    }
    
    func testGetFolderParentChildren() throws {
        let folderChildrenArray = try XCTUnwrap(nodeInfoSuccessRepository.folderChildrenInfo(fromParentHandle: HandleEntity()))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(folderChildrenArray.compactMap {$0.url}, mockArray.compactMap {$0.url})
        XCTAssertNil(nodeInfoFailureRepository.folderChildrenInfo(fromParentHandle: HandleEntity()))
    }
    
    func testGetInfoFromNode() throws {
        let nodeInfoArray = try XCTUnwrap(nodeInfoSuccessRepository.info(fromNodes: [MEGANode()]))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(nodeInfoArray.compactMap {$0.url}, mockArray.compactMap {$0.url})
        XCTAssertNil(nodeInfoFailureRepository.info(fromNodes: [MEGANode()]))
    }
    
    // MARK: - isTakenDown
    
    func testIsTakenDown_whenNotFolderLinkAndTakenDown_returnsTrue() async throws {
        let sut = makeSUT(termsOfServiceViolationResult: .success(true))
        
        let isTakenDown = try await sut.isTakenDown(node: anyNode(), isFolderLink: false)
        
        XCTAssertTrue(isTakenDown)
    }
    
    func testIsTakenDown_whenFolderLinkAndViolates_returnsTrue() async  throws {
        let sut = makeSUT(termsOfServiceViolationResult: .success(true))
        
        let isTakenDown = try await sut.isTakenDown(node: anyNode(), isFolderLink: true)
        
        XCTAssertTrue(isTakenDown)
    }
    
    func testIsTakenDown_whenFolderLinkAndNotViolates_returnsFalse() async throws {
        let sut = makeSUT(termsOfServiceViolationResult: .success(false))
        
        let isTakenDown = try await sut.isTakenDown(node: anyNode(), isFolderLink: true)
        
        XCTAssertFalse(isTakenDown)
    }
    
    func testIsTakenDown_whenFolderLinkAndError_returnsError() async {
        let expectedError = NodeInfoError.generic
        let sut = makeSUT(termsOfServiceViolationResult: .failure(expectedError))
        
        do {
            let isTakenDown = try await sut.isTakenDown(node: anyNode(), isFolderLink: true)
            XCTFail("Expect to failed but got isFolderLinkNodeTakenDown: \(isTakenDown)")
        } catch {
            XCTAssertEqual(error as! NodeInfoError, expectedError)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(termsOfServiceViolationResult: Result<Bool, NodeInfoError>) -> NodeInfoUseCase {
        let nodeInfoRepository = MockNodeInfoRepository(violatesTermsOfServiceResult: termsOfServiceViolationResult)
        let sut = NodeInfoUseCase(nodeInfoRepository: nodeInfoRepository)
        return sut
    }
    
    private func anyNode(handle: MEGAHandle = 1, name: String = "", isTakenDown: Bool = false) -> MockNode {
        MockNode(handle: handle, name: name, isTakenDown: isTakenDown)
    }
}
