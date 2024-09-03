import MEGADomain
import MEGADomainMock
import XCTest

final class SaveCollectionToFolderUseCaseTests: XCTestCase {
    private let parentFolder = NodeEntity(handle: 1, isFolder: true)
    
    func testSaveToFolder_folderCreationFailed_shouldThrowError() async {
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .failure(GenericErrorEntity()))
        let sut = makeSaveCollectionToFolderUseCase(nodeActionRepository: nodeActionRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.saveToFolder(collectionName: "New Album",
                                                                   nodes: [],
                                                                   parent: parentFolder)
        ) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
    }
    
    func testSaveToFolder_onFolderCreation_shouldCopyPublicNodes() async throws {
        let albumName = "New Album (1)"
        let albumFolder = NodeEntity(name: albumName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let copiedNodes = makeNodes()
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .success(copiedNodes))
        let sut = makeSaveCollectionToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository)
        
        let nodes = try await sut.saveToFolder(collectionName: albumName,
                                                nodes: makeNodes(),
                                                parent: parentFolder)
        XCTAssertEqual(nodes, copiedNodes)
    }
    
    func testSaveToFolder_onCopyNodesFailed_shouldThrowError() async {
        let albumName = "New Album (1)"
        let albumFolder = NodeEntity(name: albumName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let failure = CopyOrMoveErrorEntity.nodeCopyFailed
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .failure(failure))
        let sut = makeSaveCollectionToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.saveToFolder(collectionName: "New Album",
                                                                   nodes: makeNodes(),
                                                                   parent: parentFolder)
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? CopyOrMoveErrorEntity, failure)
        }
    }
    
    func testSaveToFolder_folderExistWithCollectionName_shouldAddSuffixToCollectionName() async throws {
        let albumName = "New Album"
        let childNodes = [albumName: NodeEntity(handle: 5),
                          albumName + " (1)": NodeEntity(handle: 66)]
        let nodeRepository = MockNodeRepository(childNodes: childNodes)
        let expectedFolderName = albumName + " (1) (1)"
        let albumFolder = NodeEntity(name: expectedFolderName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let copiedNodes = makeNodes()
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .success(copiedNodes))
        let sut = makeSaveCollectionToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository,
                                               nodeRepository: nodeRepository)
        
        let nodes = try await sut.saveToFolder(collectionName: albumName,
                                                nodes: makeNodes(),
                                                parent: parentFolder)
        XCTAssertEqual(nodes, copiedNodes)
        XCTAssertEqual(nodeActionRepository.createFolderName,
                       expectedFolderName)
    }
    
    // MARK: - Helpers
    
    private func makeSaveCollectionToFolderUseCase(
        nodeActionRepository: some NodeActionRepositoryProtocol = MockNodeActionRepository(),
        shareCollectionRepository: some ShareCollectionRepositoryProtocol = MockShareCollectionRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository()
    ) -> some SaveCollectionToFolderUseCaseProtocol {
        SaveCollectionToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                 shareCollectionRepository: shareCollectionRepository,
                                 nodeRepository: nodeRepository)
    }
    
    private func makeNodes(count: Int = 4) -> [NodeEntity] {
        Array(repeating: NodeEntity(handle: HandleEntity.random(), mediaType: .image),
              count: count)
    }
}
