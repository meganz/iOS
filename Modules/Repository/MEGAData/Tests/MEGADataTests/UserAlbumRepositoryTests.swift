import Combine
import MEGAData
import MEGADataMock
import MEGADomain
import XCTest

final class UserAlbumRepositoryTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadingAlbums_onRetrieved_shouldReturnAlbums() async throws {
        let megaSets = sampleSets()
        let sdk = MockSdk(megaSets: megaSets)
        let repo = UserAlbumRepository(sdk: sdk)
        
        let sets = await repo.albums()
        
        XCTAssertEqual(sets, megaSets.toSetEntities())
    }
    
    func testLoadingAlbumContent_onRetrieved_shouldReturnAlbumElements() async throws {
        let megaSetElements = sampleSetElements()
        let sdk = MockSdk(megaSetElements: megaSetElements)
        let repo = UserAlbumRepository(sdk: sdk)
        
        let setElements = await repo.albumContent(by: 1, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(setElements, megaSetElements.toSetElementsEntities())
    }
    
    func testCreateAlbum_onFinished_shouldReturnNewAlbum() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let setName = "Test Album"
        let setEntity = try await repo.createAlbum(setName)
        
        XCTAssertTrue(setEntity.name == setName)
    }
    
    func testUpdateAlbum_onFinished_shouldReturnNewName() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let newName = "New Name"
        let name = try await repo.updateAlbumName(newName, 1)
        
        XCTAssertTrue(name == newName)
    }
    
    func testDeleteAlbum_onFinished_shouldReturnDeletedAlbumId() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let deletionId: HandleEntity = 1
        let id = try await repo.deleteAlbum(by: deletionId)
        
        XCTAssertTrue(id == deletionId)
    }
    
    func testAddPhotosToAlbum_onFinished_shouldReturnPhotosAddedToAlbum() async throws {
        let nodes = sampleNodes().toNodeEntities()
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        
        let resultEntity = try await repo.addPhotosToAlbum(by: 1, nodes: nodes)
        
        XCTAssertEqual(resultEntity.success, UInt(nodes.count))
    }
    
    func testUpdateAlbumElementName_onFinish_shouldReturnNewName() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let newName = "New Set Element Name"
        let name = try await repo.updateAlbumElementName(albumId: 1, elementId: 1, name: newName)
        
        XCTAssertTrue(name == newName)
    }
    
    func testUpdateAlbumElementOrder_onFinish_shouldReturnNewOrder() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let newOrder: Int64 = 8
        let order = try await repo.updateAlbumElementOrder(albumId: 1, elementId: 1, order: newOrder)
        
        XCTAssertTrue(newOrder == order)
    }
    
    func testDeleteAlbumElementr_onFinish_shouldReturnDeletedAlbumElementId() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let elements = sampleSetElements()
        let deletionIds = elements.map({$0.handle})
        let resultEntity = try await repo.deleteAlbumElements(albumId: 1, elementIds: deletionIds)
        
        XCTAssertEqual(resultEntity.success, UInt(elements.count))
    }
    
    func testUpdateAlbumCover_onFinish_shouldReturnAlbumElementId() async throws {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let eid: UInt64 = 2
        
        let coverId = try await repo.updateAlbumCover(for: 1, elementId: eid)
        
        XCTAssertTrue(coverId == eid)
    }
    
    func testAlbumElement_onFinish_shouldReturnSetElement() async {
        let albumId: UInt64 = 5
        let elementId: UInt64 = 3
        let expected = MockMEGASetElement(handle: elementId, ownerId: albumId,
                                          order: 4, nodeId: 1)
        let sdk = MockSdk(megaSetElements: sampleSetElements() + [expected])
        let repo = UserAlbumRepository(sdk: sdk)
        
        let albumElement = await repo.albumElement(by: albumId, elementId: elementId)
        XCTAssertEqual(albumElement, expected.toSetElementEntity())
    }
    
    func testSetsUpdatedPublisher_onSetsUpdate_sendsUpdatedSets() {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let expectedSets = sampleSets()
        
        let exp = expectation(description: "Should receive set update")
        repo.setsUpdatedPublisher
            .sink {
                XCTAssertEqual($0, expectedSets.toSetEntities())
                exp.fulfill()
            }.store(in: &subscriptions)
        repo.onSetsUpdate(sdk, sets: expectedSets)
        wait(for: [exp], timeout: 1)
    }
    
    func testSetElementsUpdatedPublisher_onSetElementsUpdate_sendsUpdatedSetElements() {
        let sdk = MockSdk()
        let repo = UserAlbumRepository(sdk: sdk)
        let expectedSetElements = sampleSetElements()
        
        let exp = expectation(description: "Should receive set elements update")
        repo.setElemetsUpdatedPublisher
            .sink {
                XCTAssertEqual($0, expectedSetElements.toSetElementsEntities())
                exp.fulfill()
            }.store(in: &subscriptions)
        
        repo.onSetElementsUpdate(sdk, setElements: expectedSetElements)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: Private
    
    private func sampleSets() -> [MockMEGASet] {
        let set1 = MockMEGASet(handle: 1, userId: 0, coverId: 1)
        let set2 = MockMEGASet(handle: 2, userId: 0, coverId: 2)
        let set3 = MockMEGASet(handle: 3, userId: 0, coverId: 3)
        
        return [set1, set2, set3]
    }
    
    private func sampleSetElements() -> [MockMEGASetElement] {
        let setElement1 = MockMEGASetElement(handle: 1, ownerId: 3, order: 0, nodeId: 1)
        let setElement2 = MockMEGASetElement(handle: 2, ownerId: 3, order: 0, nodeId: 2)
        
        return [setElement1, setElement2]
    }
    
    private func sampleNodes() -> [MockNode] {
        let node0 = MockNode(handle: 0, name: "Test0", parentHandle: 0)
        let node1 = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "Test2", parentHandle: 0)
        
        return [node0, node1, node2]
    }
}
