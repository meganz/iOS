import XCTest
import MEGADomain
@testable import MEGA

final class UserAlbumRepositoryTests: XCTestCase {
    
    func testLoadingAlbums_onRetrieved_shouldReturnTrue() async throws {
        let megaSets = sampleSets()
        let sdk = MockSdk(megaSets:megaSets)
        let repo = UserAlbumRepository(sdk: sdk)
        
        let sets = await repo.albums()
        
        XCTAssertEqual(sets.count, megaSets.count)
    }
    
    func testLoadingAlbumContent_onRetrieved_shouldReturnTrue() async throws {
        let megaSetElements = sampleSetElements()
        let sdk = MockSdk(megaSetElements: megaSetElements)
        let repo = UserAlbumRepository(sdk: sdk)
        
        let setElements = await repo.albumContent(by: 1)
        
        XCTAssertEqual(setElements.count, megaSetElements.count)
    }
    
    func testCreateAlbum_onFinished_shouldReturnTrue() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let setName = "Test Album"
        let setEntity = try await repo.createAlbum(setName)
        
        XCTAssertTrue(setEntity.name == setName)
    }
    
    func testUpdateAlbum_onFinished_shouldReturnTrue() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let newName = "New Name"
        let name = try await repo.updateAlbumName(newName, 1)
        
        XCTAssertTrue(name == newName)
    }
    
    func testDeleteAlbum_onFinished_shouldReturnTrue() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let deletionId: HandleEntity = 1
        let id = try await repo.deleteAlbum(by: deletionId)
        
        XCTAssertTrue(id == deletionId)
    }
    
    // MARK: Private
    
    private func sampleSets() -> [MockMEGASet] {
        let set1 = MockMEGASet(handle: 1, userId: 0, coverId: 1)
        let set2 = MockMEGASet(handle: 2, userId: 0, coverId: 2)
        let set3 = MockMEGASet(handle: 3, userId: 0, coverId: 3)
        
        return [set1,set2,set3]
    }
    
    private func sampleSetElements() -> [MockMEGASetElement] {
        let setElement1 = MockMEGASetElement(handle: 1, order: 0, nodeId: 1)
        let setElement2 = MockMEGASetElement(handle: 2, order: 0, nodeId: 2)
        
        return [setElement1,setElement2]
    }
}
