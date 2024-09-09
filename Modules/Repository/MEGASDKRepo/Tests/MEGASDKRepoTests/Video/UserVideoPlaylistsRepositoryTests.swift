import MEGADomain
@testable import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class UserVideoPlaylistsRepositoryTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenCalled_doesNotGetSets() async {
        let (_, sdk) = makeSUT()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 0)
    }
    
    // MARK: - VideoPlaylists
    
    func testVideoPlaylists_whenCalled_getSets() async {
        let (sut, sdk) = makeSUT()
        
        _ = await sut.videoPlaylists()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 1)
    }
    
    func testVideoPlaylists_whenCalledTwice_getSetsTwice() async {
        let (sut, sdk) = makeSUT()
        
        _ = await sut.videoPlaylists()
        _ = await sut.videoPlaylists()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 2)
    }
    
    func testVideoPlaylists_whenHasNoPlaylists_deliversEmptyItems() async {
        let (sut, _) = makeSUT()
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertEqual(videoPlaylists, [], "Expect to have empty items")
    }
    
    func testVideoPlaylists_whenHasSets_deliversOnlyVideoPlaylists() async {
        let sets = [
            MockMEGASet(handle: 1, type: .invalid),
            MockMEGASet(handle: 2, type: .album),
            MockMEGASet(handle: 3, type: .playlist)
        ]
        let (sut, _) = makeSUT(megaSets: sets)
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertTrue(videoPlaylists.allSatisfy { $0.setType == .playlist }, "Should only contains playlist type only")
    }
    
    func testVideoPlaylists_whenHasMoreThanOnePlaylists_deliversNonEmptyItems() async {
        let sets = [
            MockMEGASet(handle: 1, type: .playlist),
            MockMEGASet(handle: 2, type: .playlist),
            MockMEGASet(handle: 3, type: .playlist)
        ]
        let (sut, _) = makeSUT(megaSets: sets)
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertEqual(videoPlaylists.count, sets.count, "should deliver more than one playlist")
    }
    
    // MARK: - addVideosToVideoPlaylist
    
    func testAddVideosToVideoPlaylist_whenNodesIsEmpty_doesNotAddVideosToVideoPlaylists() async {
        let (sut, _) = makeSUT()
        
        do {
            _ = try await sut.addVideosToVideoPlaylist(by: 1, nodes: [])
            XCTFail("Expect to catch, but not throwing instead")
        } catch {
            XCTAssertEqual(error as? VideoPlaylistErrorEntity, .invalidOperation)
        }
    }
    
    func testAddVideosToVideoPlaylist_whenNodesNotEmpty_createSetElement() async throws {
        let (sut, sdk) = makeSUT()
        let videosToAdd = [
            anyNode(id: 1),
            anyNode(id: 2)
        ]
        
        _ = try await sut.addVideosToVideoPlaylist(by: 1, nodes: videosToAdd)
        
        let messagesCount = sdk.messages
            .filter {
                if case .createSetElement = $0 {
                    true
                } else {
                    false
                }
            }
            .count
        XCTAssertTrue(messagesCount != 0)
    }
    
    // MARK: - videoPlaylistContent
    
    func testVideoPlaylistContent_onRetrieved_shouldReturnVideoPlaylistElements() async {
        let megaSetElements = sampleSetElements()
        let (sut, _) = makeSUT(megaSetElements: megaSetElements)
        
        let setElements = await sut.videoPlaylistContent(by: 1, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(setElements, megaSetElements.toSetElementsEntities())
    }
    
    // MARK: - deleteVideoPlaylist
    
    func testDeleteVideoPlaylist_whenCalled_removeSet() async {
        let videoPlaylistToDelete = userVideoPlaylist(id: 1)
        let (sut, sdk) = makeSUT()
        
        _ = try? await sut.deleteVideoPlaylist(by: videoPlaylistToDelete)
        
        XCTAssertEqual(sdk.messages, [ .removeSet(sid: videoPlaylistToDelete.id) ])
    }
    
    // MARK: - createVideoPlaylist
    
    func testCreateVideoPlaylist_whenCalled_createsVideoPlaylistByName() async {
        let expectedPlaylistName = "any video playlist name"
        let (sut, sdk) = makeSUT()
        
        _ = try? await sut.createVideoPlaylist(expectedPlaylistName)
        
        XCTAssertEqual(sdk.messages, [ .createSet(name: expectedPlaylistName, type: .playlist) ])
    }
    
    // MARK: - updateVideoPlaylistName
    
    func testUpdateVideoPlaylistName_whenCalled_updatesVideoPlaylistName() async {
        let videoPlaylistToBeRenamed = userVideoPlaylist(id: 1)
        let newName = "new name"
        let (sut, sdk) = makeSUT()
        
        _ = try? await sut.updateVideoPlaylistName(newName, for: videoPlaylistToBeRenamed)
        
        XCTAssertEqual(sdk.messages, [ .updateSetName(sid: videoPlaylistToBeRenamed.id, name: newName) ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        megaSets: [MockMEGASet] = [],
        megaSetElements: [MockMEGASetElement] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: UserVideoPlaylistsRepository,
        sdk: MockSdk
    ) {
        let sdk = MockSdk(megaSets: megaSets, megaSetElements: megaSetElements)
        let sut = UserVideoPlaylistsRepository(
            sdk: sdk,
            setAndElementsUpdatesProvider: MockSetAndElementUpdatesProvider()
        )
        return (sut, sdk)
    }
    
    private func anyNode(id: HandleEntity) -> NodeEntity {
        NodeEntity(
            changeTypes: .favourite,
            nodeType: .file,
            name: "",
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            isFavourite: false,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: .video
        )
    }
    
    private func sampleSetElements(ownerId: HandleEntity = 3) -> [MockMEGASetElement] {
        [
            MockMEGASetElement(handle: 1, ownerId: ownerId, order: 0, nodeId: 1),
            MockMEGASetElement(handle: 2, ownerId: ownerId, order: 0, nodeId: 2)
        ]
    }
    
    private func userVideoPlaylist(id: HandleEntity) -> VideoPlaylistEntity {
        VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: id), name: "name: \(id)", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
    }
}
