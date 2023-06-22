@testable import MEGA
import XCTest

final class OfflineFileInfoUseCaseTests: XCTestCase {
    let offlineFileInfoSuccessRepository = MockOfflineInfoRepository(result: .success(()))
    let offlineFileInfoFailureRepository = MockOfflineInfoRepository(result: .failure(.generic))
    
    func testGetInfoFromFolderLinkNode() throws {
        let folderLinkNodesArray = try XCTUnwrap(offlineFileInfoSuccessRepository.info(fromFiles: [""]))
        let mockArray = try XCTUnwrap(AudioPlayerItem.mockArray)
        
        XCTAssertEqual(folderLinkNodesArray.compactMap {$0.url}, mockArray.compactMap {$0.url})
        XCTAssertNil(offlineFileInfoFailureRepository.info(fromFiles: [""]))
    }
    
    func testGetNodeLocalPath() throws {
        let nodePath = try XCTUnwrap(offlineFileInfoSuccessRepository.localPath(fromNode: MEGANode()))
        let mockNodePath = try XCTUnwrap(AudioPlayerItem.mockItem.url)
        
        XCTAssertEqual(nodePath, mockNodePath)
        XCTAssertNil(offlineFileInfoFailureRepository.localPath(fromNode: MEGANode()))
    }
}
