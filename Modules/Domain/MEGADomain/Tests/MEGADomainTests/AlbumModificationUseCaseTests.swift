import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumModificationUseCaseTests: XCTestCase {
    func testAddPhotosToAlbum_onAlbumCreated_shouldReturnPhotosAddedToAlbum() async throws {
        let nodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: false)
        ]
        let addResult = AlbumElementsResultEntity(success: UInt(nodes.count), failure: 0)
        let userAlbumRepository = MockUserAlbumRepository(
            addPhotosResult: .success(addResult))
        let sut = AlbumModificationUseCase(userAlbumRepo: userAlbumRepository)
        
        let result = try await sut.addPhotosToAlbum(by: 1, nodes: nodes)
        XCTAssert(result.success == nodes.count)
    }
    
    func testRename_onAlbumRename_shouldReturnNewName() async throws {
        let updateName = "Hey There"
        let userAlbumRepository = MockUserAlbumRepository(updateAlbumNameResult: .success(updateName))
        let sut = AlbumModificationUseCase(userAlbumRepo: userAlbumRepository)
        
        let newName = try await sut.rename(album: HandleEntity(1), with: updateName)

        XCTAssertEqual(newName, updateName)
    }
    
    func testUpdateAlbumCover_onAlbumCoverUpdate_shouldReturnUpdatedCoverNode() async throws {
        let coverHandle = HandleEntity(2)
        let setElem1 = SetElementEntity(handle: HandleEntity(1), ownerId: HandleEntity(1), order: HandleEntity(1), nodeId: HandleEntity(1), modificationTime: Date.distantPast, name: "1")
        let setElem2 = SetElementEntity(handle: coverHandle, ownerId: HandleEntity(2), order: HandleEntity(2), nodeId: HandleEntity(2), modificationTime: Date.distantPast, name: "2")
        
        let albumContents: [HandleEntity: [SetElementEntity]] = [
            HandleEntity(1): [setElem1, setElem2]
        ]
        
        let sut = AlbumModificationUseCase(userAlbumRepo: MockUserAlbumRepository(albumContent: albumContents, updateAlbumCoverResult: .success(coverHandle)))
        
        let nodeId = try await sut.updateAlbumCover(album: HandleEntity(1),
                                                    withAlbumPhoto: AlbumPhotoEntity(photo: NodeEntity(handle: HandleEntity(2)), albumPhotoId: coverHandle))

        XCTAssertEqual(nodeId, coverHandle)
    }
    
    func testUpdateAlbumCover_onAlbumCoverUpdate_shouldThrowErrorForMissingPhotoId() async throws {
        let setElem1 = SetElementEntity(handle: HandleEntity(1), ownerId: HandleEntity(1), order: HandleEntity(1), nodeId: HandleEntity(1), modificationTime: Date.distantPast, name: "1")
        let setElem2 = SetElementEntity(handle: HandleEntity(2), ownerId: HandleEntity(2), order: HandleEntity(2), nodeId: HandleEntity(2), modificationTime: Date.distantPast, name: "2")
        
        let albumContents: [HandleEntity: [SetElementEntity]] = [
            HandleEntity(1): [setElem1, setElem2]
        ]
        
        let sut = AlbumModificationUseCase(userAlbumRepo: MockUserAlbumRepository(albumContent: albumContents))
        
        do {
            _ = try await sut.updateAlbumCover(album: HandleEntity(1), withAlbumPhoto: AlbumPhotoEntity(photo: NodeEntity(handle: HandleEntity(2)), albumPhotoId: nil))
        } catch let errorEntity as AlbumPhotoErrorEntity {
            XCTAssertTrue(errorEntity == .photoIdDoesNotExist)
        }
    }
    
    func testDeletePhotos_onAlbumPhotoEntityWithNoValidIds_shouldReturnZeroAlbumResultEntity() async throws {
        let sut = AlbumModificationUseCase(userAlbumRepo: MockUserAlbumRepository.newRepo)
        let album = AlbumEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        let photosToRemove = [AlbumPhotoEntity(photo: NodeEntity(handle: 1), albumPhotoId: nil)]
        let result = try await sut.deletePhotos(in: album.id, photos: photosToRemove)
        XCTAssertEqual(result.success, 0)
        XCTAssertEqual(result.failure, 0)
    }
    
    func testDeletePhotos_onAlbumPhotoEntityWithValidPhotoIds_shouldReturnAlbumResultEntityWithIdCount() async throws {
        let photosToRemove = [AlbumPhotoEntity(photo: NodeEntity(handle: 1), albumPhotoId: 1),
                              AlbumPhotoEntity(photo: NodeEntity(handle: 2), albumPhotoId: 2)]
        let expectedAlbumResult = AlbumElementsResultEntity(success: UInt(photosToRemove.count), failure: 0)
        let userAlbumRepository = MockUserAlbumRepository(deleteAlbumElementsResult: .success(expectedAlbumResult))
        let sut = AlbumModificationUseCase(userAlbumRepo: userAlbumRepository)
        let album = AlbumEntity(id: 1, name: "Custom", coverNode: nil, count: 1, type: .user)
        
        let result = try await sut.deletePhotos(in: album.id, photos: photosToRemove)
        XCTAssertEqual(result.success, expectedAlbumResult.success)
        XCTAssertEqual(result.failure, expectedAlbumResult.failure)
    }
    
    func testAlbumDelete_whenUserWantToDelete_shouldDeleteAlbum() async {
        let sut = AlbumModificationUseCase(userAlbumRepo: MockUserAlbumRepository.newRepo)

        let deletedAlbumIds = [HandleEntity(1), HandleEntity(2)]

        let ids = await sut.delete(albums: deletedAlbumIds).sorted()
        XCTAssertEqual(ids, deletedAlbumIds)
    }
}
