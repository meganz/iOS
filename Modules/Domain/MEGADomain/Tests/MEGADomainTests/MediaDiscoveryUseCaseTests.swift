import MEGADomain
import MEGADomainMock
import XCTest

final class MediaDiscoveryUseCaseTests: XCTestCase {
    func testLoadNodes_forParentNode_returnsCorrectNodes() async {
        let photoNodes = [NodeEntity(name: "0.jpg", handle: 1, isFile: true)]
        let videoNodes = [NodeEntity(name: "1.mp4", handle: 2, isFile: true)]
        let expectedNodes = photoNodes + videoNodes
        let parentNode = NodeEntity(name: "parent", handle: 0)
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [parentNode.handle: photoNodes + videoNodes])
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        do {
            let nodes = try await useCase.nodes(forParent: parentNode, recursive: false, excludeSensitive: false)
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
        
        XCTAssertEqual(fileSearchRepo.searchString, "")
        XCTAssertFalse(fileSearchRepo.searchRecursive ?? true)
    }
    
    func testLoadNodes_forParentNodeAndExcludesSensitives_returnsCorrectNodes() async {
        let photoNodes = [NodeEntity(name: "0.jpg", handle: 1, isFile: true, isMarkedSensitive: true)]
        let videoNodes = [NodeEntity(name: "1.mp4", handle: 2, isFile: true)]
        let expectedNodes = videoNodes
        let parentNode = NodeEntity(name: "parent", handle: 0)
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [parentNode.handle: photoNodes + videoNodes])
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        do {
            let nodes = try await useCase.nodes(forParent: parentNode, recursive: false, excludeSensitive: true)
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
        
        XCTAssertEqual(fileSearchRepo.searchString, "")
        XCTAssertFalse(fileSearchRepo.searchRecursive ?? true)
    }
    
    func testLoadNodes_forParentNode_returnsNodesRecursively() async {
        let nodePhotoParent = NodeEntity(nodeType: .folder, name: "Inner Photo", handle: 100, isFolder: true)
        let nodeVideoParent = NodeEntity(nodeType: .folder, name: "Inner Video", handle: 200, isFolder: true)
        let photoNode1 = NodeEntity(name: "1.jpg", handle: 1, isFile: true)
        let photoNode2 = NodeEntity(name: "2.jpg", handle: 2, parentHandle: 100, isFile: true)
        let videoNode1 = NodeEntity(name: "5.mp4", handle: 5, isFile: true)
        let videoNode2 = NodeEntity(name: "6.mp4", handle: 6, parentHandle: 200, isFile: true)
        let photoNodes = [photoNode1, nodePhotoParent, photoNode2]
        let videoNodes = [videoNode1, nodeVideoParent, videoNode2]
        let expectedNodes = [photoNode1, photoNode2, videoNode1, videoNode2]
        let parentNode = NodeEntity(name: "parent", handle: 0)
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [parentNode.handle: photoNodes + videoNodes])
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        
        do {
            let nodes = try await useCase.nodes(forParent: parentNode, recursive: true, excludeSensitive: false)
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
        
        XCTAssertEqual(fileSearchRepo.searchString, "")
        XCTAssertTrue(fileSearchRepo.searchRecursive ?? false)
    }
    
    func testLoadNodes_forParentNodeAndExcludesSensitive_returnsNodesRecursively() async {
        let nodePhotoParent = NodeEntity(nodeType: .folder, name: "Inner Photo", handle: 100, isFolder: true)
        let nodeVideoParent = NodeEntity(nodeType: .folder, name: "Inner Video", handle: 200, isFolder: true)
        let photoNode1 = NodeEntity(name: "1.jpg", handle: 1, isFile: true, isMarkedSensitive: true)
        let photoNode2 = NodeEntity(name: "2.jpg", handle: 2, parentHandle: 100, isFile: true)
        let videoNode1 = NodeEntity(name: "5.mp4", handle: 5, isFile: true)
        let videoNode2 = NodeEntity(name: "6.mp4", handle: 6, parentHandle: 200, isFile: true)
        let photoNodes = [photoNode1, nodePhotoParent, photoNode2]
        let videoNodes = [videoNode1, nodeVideoParent, videoNode2]
        let expectedNodes = [photoNode2, videoNode1, videoNode2]
        let parentNode = NodeEntity(name: "parent", handle: 0)
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [parentNode.handle: photoNodes + videoNodes])
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        
        do {
            let nodes = try await useCase.nodes(forParent: parentNode, recursive: true, excludeSensitive: true)
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
        
        XCTAssertEqual(fileSearchRepo.searchString, "")
        XCTAssertTrue(fileSearchRepo.searchRecursive ?? false)
    }
    
    func testNodeUpdates_shouldYieldUpdates() async {
        let nodeEntities = [
            [NodeEntity(handle: 1)],
            [NodeEntity(handle: 2), NodeEntity(handle: 3)]
        ]
        
        let fileSearchRepo = MockFilesSearchRepository(nodeUpdates: nodeEntities.async.eraseToAnyAsyncSequence())
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)

        let task = Task {
            var results: [[NodeEntity]] = []
            for await nodes in useCase.nodeUpdates {
                results.append(nodes)
            }
            return results
        }
        
        let results = await task.value
        
        XCTAssertEqual(results.flatMap { $0.map(\.handle) }, [1, 2, 3])
    }
    
    // MARK: Should reload
    
    func testShouldReload_onShouldProcessNodesUpdateReturnFalse_shouldReturnFalse() {
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: nodeUpdateRepository)
        
        XCTAssertFalse(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(handle: 3)]))
    }

    func testShouldReload_onShouldProcessNodesUpdateReturnTrue_shouldReturnTrue() {
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: true)
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: nodeUpdateRepository)
        
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(handle: 3)]))
    }
}
