import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class FileSearchRepositoryTests: XCTestCase {
    
    private let rootNode = MockNode(handle: 0, name: "root")
    
    func testAllPhotos_onFileSearchNodeList_shouldReturnPhotos() async throws {
        let nodes = photoNodes()
        let sdk = MockSdk(nodes: nodes, megaRootNode: rootNode)
        let repo = FileSearchRepository(sdk: sdk)
        let photos = try await repo.allPhotos()
        XCTAssertEqual(photos.count, nodes.count)
    }
    
    func testAllVideos_onFileSearchNodeList_shouldReturnVideos() async throws {
        let nodes = videoNodes()
        let sdk = MockSdk(nodes: nodes, megaRootNode: rootNode)
        let repo = FileSearchRepository(sdk: sdk)
        let videos = try await repo.allVideos()
        XCTAssertEqual(videos.count, nodes.count)
    }
    
    func testStartMonitoring_onAlbumScreen_shouldSetCallBack() throws {
        let sdk = MockSdk()
        let repo = FileSearchRepository(sdk: sdk)
        
        repo.startMonitoringNodesUpdate(callback: { _ in })
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
    }
    
    func testStopMonitoring_onAlbumScreen_shouldSetCallBackToNil() throws {
        let sdk = MockSdk()
        let repo = FileSearchRepository(sdk: sdk)
        
        repo.stopMonitoringNodesUpdate()
        
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    // MARK: Private
    
    private func photoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.raw"),
                     MockNode(handle: 2, name: "2.nef"),
                     MockNode(handle: 3, name: "3.cr2"),
                     MockNode(handle: 4, name: "4.dng"),
                     MockNode(handle: 5, name: "5.gif")]
    }
    
    private func videoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.mp4"),
                     MockNode(handle: 2, name: "2.mov")]
    }
}
