import XCTest
import MEGADomain
import MEGADomainMock


final class FilesSearchUseCaseTests: XCTestCase {
    
    func testSearchAllPhotos_shouldReturnAllPhotosNodes() {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true),
        ]
        
        let sut = FilesSearchUseCase(repo: MockFilesSearchRepository(photoNodes: nodes),
                                     nodeFormat: NodeFormatEntity.photo,
                                     nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo)
        
        sut.search(string: "", parent: nil, sortOrderType: .none, cancelPreviousSearchIfNeeded: false) { results, fail in
            guard let results else { XCTFail("Search results shouldn't be nil"); return }
            
            XCTAssertEqual(results, nodes)
        }
    }
    
    func testOnNodeUpdate_updatedNodesShouldBeTheSame() {
        let nodesUpdated = [
            NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true)
        ]
        let mockNodeUpdateListenerRepo = MockSDKNodesUpdateListenerRepository.newRepo
        let sut = FilesSearchUseCase(repo: MockFilesSearchRepository.newRepo,
                                     nodeFormat: NodeFormatEntity.photo,
                                     nodesUpdateListenerRepo: mockNodeUpdateListenerRepo)
        
        sut.onNodesUpdate { results in
            XCTAssertEqual(results, nodesUpdated)
        }
        
        mockNodeUpdateListenerRepo.onNodesUpdateHandler?(nodesUpdated)
    }
    
    func testSearchPhotosCancelled_CancelSearchShouldReturnTrue() {
        let repo = MockFilesSearchRepository.newRepo
        let sut = FilesSearchUseCase(repo: repo,
                                     nodeFormat: NodeFormatEntity.photo,
                                     nodesUpdateListenerRepo: MockSDKNodesUpdateListenerRepository.newRepo)
        
        sut.search(string: "", parent: nil, sortOrderType: .none, cancelPreviousSearchIfNeeded: true) { results, fail in
            XCTAssertTrue(repo.hasCancelSearchCalled)
        }
    }
}
