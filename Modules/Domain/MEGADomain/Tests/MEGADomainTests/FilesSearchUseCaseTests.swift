import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class FilesSearchUseCaseTests: XCTestCase {
    
    func testSearchWithFilter_shouldReturnAllPhotosNodes() async throws {
        let expectedNodes = [
            NodeEntity(name: "sample1.raw", handle: 1, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, isFile: true, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, isFile: true, hasThumbnail: true)
        ]
        
        let allNodes = expectedNodes + [
            NodeEntity(name: "test3.mp4", handle: 5, isFile: true, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForLocation: [.rootNode: allNodes])
        )
        let results: [NodeEntity] = try await sut.search(
            filter: .recursive(
                searchText: "",
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: false,
                sortOrderType: .none,
                formatType: .photo,
                sensitiveFilterOption: .disabled
            ),
            cancelPreviousSearchIfNeeded: false
        )
        XCTAssertEqual(results, expectedNodes)
    }
    
    func testSearchWithFilterAsync_shouldReturnAllPhotosNodes() async throws {
        let expectedNodes = [
            NodeEntity(name: "sample1.raw", handle: 1, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, isFile: true, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, isFile: true, hasThumbnail: true)
        ]
        
        let allNodes = expectedNodes + [
            NodeEntity(name: "test3.mp4", handle: 5, isFile: true, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForLocation: [.rootNode: allNodes]))
        
        let results: [NodeEntity] = try await sut.search(
            filter: .recursive(
                searchText: "",
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: false,
                sortOrderType: .none,
                formatType: .photo,
                sensitiveFilterOption: .disabled)
            ,
            cancelPreviousSearchIfNeeded: false
        )
        XCTAssertEqual(results, expectedNodes)
    }
    
    func testSearchWithFilterAsyncAndPagedResult_shouldReturnSlicedPhotosNodes() async throws {
        let expectedNodes = [
            NodeEntity(name: "sample1.raw", handle: 1, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, isFile: true, hasThumbnail: false)
        ]
        
        let allNodes = expectedNodes + [
            NodeEntity(name: "test2.jpg", handle: 3, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, isFile: true, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, isFile: true, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, isFile: true, hasThumbnail: true)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForLocation: [.rootNode: allNodes]))
        
        let results: [NodeEntity] = try await sut.search(
            filter: .recursive(
                searchText: "",
                searchTargetLocation: .folderTarget(.rootNode),
                supportCancel: false,
                sortOrderType: .none,
                formatType: .photo,
                sensitiveFilterOption: .disabled)
            ,
            page: SearchPageEntity(startingOffset: 0, pageSize: 2),
            cancelPreviousSearchIfNeeded: false
        )
        XCTAssertEqual(results, expectedNodes)
    }
    
    // MARK: - nodeUpdates
    
    func testNodeUpdates_whenHasNoNodeUpdates_shouldNotEmitsUpdate() async {
        let sut = makeSUT(
            nodeRepository: MockNodeRepository()
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
        nodeRepository: MockNodeRepository = MockNodeRepository.newRepo
    ) -> FilesSearchUseCase {
        FilesSearchUseCase(
            repo: filesSearchRepository,
            nodeRepository: nodeRepository
        )
    }
}
