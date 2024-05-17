import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class FilesSearchUseCaseTests: XCTestCase {
    
    func testSearchAllPhotos_shouldReturnAllPhotosNodes() {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(photoNodes: nodes),
            nodeFormat: NodeFormatEntity.photo,
            nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo
        )
        
        sut.search(string: "", parent: nil, recursive: true, supportCancel: false, sortOrderType: .none, cancelPreviousSearchIfNeeded: false) { results, _ in
            guard let results else { XCTFail("Search results shouldn't be nil"); return }
            
            XCTAssertEqual(results, nodes)
        }
    }
    
    func testSearchWithFilter_shouldReturnAllPhotosNodes() {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(photoNodes: nodes),
            nodeFormat: NodeFormatEntity.photo,
            nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo
        )
        sut.search(filter: .init(searchText: "", parentNode: nil, recursive: true, supportCancel: false, sortOrderType: .none, formatType: .photo, excludeSensitive: false), cancelPreviousSearchIfNeeded: false) { results, _ in
            guard let results else { XCTFail("Search results shouldn't be nil"); return }
            
            XCTAssertEqual(results, nodes)
        }
    }
    
    func testSearchWithFilterAsync_shouldReturnAllPhotosNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, isFile: true, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, isFile: true, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(photoNodes: nodes),
            nodeFormat: NodeFormatEntity.photo,
            nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo
        )
        let results = try await sut.search(filter: .init(searchText: "", parentNode: nil, recursive: true, supportCancel: false, sortOrderType: .none, formatType: .photo, excludeSensitive: false), cancelPreviousSearchIfNeeded: false)
        XCTAssertEqual(results, nodes)
    }
    
    func testOnNodeUpdate_updatedNodesShouldBeTheSame() {
        let nodesUpdated = [
            NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true)
        ]
        let mockNodeUpdateListenerRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(photoNodes: nodesUpdated),
            nodeFormat: NodeFormatEntity.photo,
            nodesUpdateListenerRepo: mockNodeUpdateListenerRepo
        )
        
        sut.onNodesUpdate { results in
            XCTAssertEqual(results, nodesUpdated)
        }
        
        mockNodeUpdateListenerRepo.onNodesUpdateHandler?(nodesUpdated)
    }
    
    func testSearchPhotosCancelled_CancelSearchShouldReturnTrue() {
        let repo = MockFilesSearchRepository.newRepo
        let sut = makeSUT(
            filesSearchRepository: repo,
            nodeFormat: NodeFormatEntity.photo,
            nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo
        )
        
        sut.search(string: "", parent: nil, recursive: true, supportCancel: false, sortOrderType: .none, cancelPreviousSearchIfNeeded: true) { _, _ in
            XCTAssertTrue(repo.hasCancelSearchCalled)
        }
    }
    
    // MARK: - nodeUpdates
    
    func testNodeUpdates_whenHasNoNodeUpdates_shouldNotEmitsUpdate() async {
        let sut = makeSUT(
            nodeRepository: MockNodeRepository(nodeUpdates: EmptyAsyncSequence().eraseToAnyAsyncSequence())
        )
        
        var receivedNodeUpdates: [NodeEntity] = []
        for await nodes in sut.nodeUpdates {
            receivedNodeUpdates.append(contentsOf: nodes)
        }
        
        XCTAssertTrue(receivedNodeUpdates.isEmpty)
    }
    
    func testNodeUpdates_whenHasNodeUpdates_emitsUpdate() async {
        let expectedResults = [ NodeEntity(name: "node-1", handle: 1), NodeEntity(name: "node-2", handle: 2) ]
        let nodeUpdatesStream = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield([expectedResult])
            }
            continuation.finish()
        }
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(
            nodeFormat: NodeFormatEntity.video,
            nodeRepository: MockNodeRepository(nodeUpdates: nodeUpdatesStream)
        )
        
        var receivedNodeUpdates: [NodeEntity] = []
        for await nodes in sut.nodeUpdates {
            receivedNodeUpdates.append(contentsOf: nodes)
        }
        
        XCTAssertTrue(receivedNodeUpdates.isNotEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        filesSearchRepository: MockFilesSearchRepository = MockFilesSearchRepository.newRepo,
        nodeFormat: NodeFormatEntity = .photo,
        nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository = MockSDKNodesUpdateListenerRepository.newRepo,
        nodeRepository: MockNodeRepository = MockNodeRepository.newRepo
    ) -> FilesSearchUseCase {
        FilesSearchUseCase(
            repo: filesSearchRepository,
            nodeFormat: nodeFormat,
            nodesUpdateListenerRepo: nodesUpdateListenerRepo,
            nodeRepository: nodeRepository
        )
    }
}
