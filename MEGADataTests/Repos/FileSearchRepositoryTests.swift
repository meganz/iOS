import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class FileSearchRepositoryTests: XCTestCase {
    
    private let photos = [
            NodeEntity(name: "1.raw", handle: 1),
            NodeEntity(name: "2.nef", handle: 2),
            NodeEntity(name: "3.cr2", handle: 3),
            NodeEntity(name: "4.dng", handle: 4),
            NodeEntity(name: "5.gif", handle: 5)]
    
    func testAllPhotos_onAlbumScreen_shouldReturnPhotos() async throws {
        let sut = MockFileSearchRepository(nodes: photos)
        let photos = try await sut.allPhotos()
        
        XCTAssertTrue(photos.count == photos.count)
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
}
