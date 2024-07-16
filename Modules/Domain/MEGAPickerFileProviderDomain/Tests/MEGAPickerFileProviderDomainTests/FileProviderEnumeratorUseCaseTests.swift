import FileProvider
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import MEGATest
import XCTest

final class FileProviderEnumeratorUseCaseTests: XCTestCase {
    
    func testFetchItems_whenIdentifierIsRoot_returnsAllNodesUnderRoot() async throws {
        let rootNode = NodeEntity(handle: 0, base64Handle: "0", isFolder: true)
        let expectedNodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 4)
        ]
        let sut = sut(
            filesSearchRepo: MockFilesSearchRepository(nodesForHandle: [rootNode.handle: expectedNodes]),
            nodeRep: MockNodeRepository(node: rootNode, nodeRoot: rootNode))
        
        let results = try await sut.fetchItems(for: NSFileProviderItemIdentifier.rootContainer)
        
        XCTAssertEqual(results, expectedNodes)
    }
    
    func testFetchItems_whenIdentifierIsFolder_returnsAllNodesUnderFolder() async throws {
        let folderNode = NodeEntity(handle: 12312, base64Handle: "12312", isFolder: true)
        let expectedNodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 4)
        ]

        let sut = sut(
            filesSearchRepo: MockFilesSearchRepository(nodesForHandle: [folderNode.handle: expectedNodes]),
            nodeRep: MockNodeRepository(node: folderNode))
        
        let results = try await sut.fetchItems(for: NSFileProviderItemIdentifier(folderNode.base64Handle))
        
        XCTAssertEqual(results, expectedNodes)
    }
    
    func testFetchItems_whenIdentifierIsFile_returnsFileNodeOnly() async throws {
        let fileNode = NodeEntity(handle: 12312, base64Handle: "12312", isFolder: false)
        let sut = sut(
            nodeRep: MockNodeRepository(node: fileNode))
        
        let results = try await sut.fetchItems(for: NSFileProviderItemIdentifier(fileNode.base64Handle))
        
        XCTAssertEqual(results, [fileNode])
    }
    
    func testFetchItems_whenIdentifierIsFolderAndContainsSensitiveNodes_returnsOnlyNonSensitiveNodesInFolder() async throws {
        
        let folderNode = NodeEntity(handle: 12312, base64Handle: "12312", isFolder: true)
        let expectedNodes = [
            NodeEntity(handle: 1, isMarkedSensitive: false),
            NodeEntity(handle: 4, isMarkedSensitive: false)
        ]
        let allNodesInFolder = [
            NodeEntity(handle: 2, isMarkedSensitive: true)
        ] + expectedNodes

        let sut = sut(
            filesSearchRepo: MockFilesSearchRepository(nodesForHandle: [folderNode.handle: allNodesInFolder]),
            nodeRep: MockNodeRepository(node: folderNode))
        
        let results = try await sut.fetchItems(for: NSFileProviderItemIdentifier(folderNode.base64Handle))
        
        XCTAssertEqual(results.count, expectedNodes.count)
    }
    
    func testFetchItems_whenIdentifierIsNotANode_throwsError() async throws {
        let sut = sut(
            megaHandleRepo: MockMEGAHandleRepository())
        
        await XCTAsyncAssertThrowsError(try await sut.fetchItems(for: NSFileProviderItemIdentifier("invalid node handle"))) { error in
            XCTAssertEqual(error as? NSFileProviderError, NSFileProviderError(.noSuchItem))
        }
    }
}

extension FileProviderEnumeratorUseCaseTests {
    func sut(
        filesSearchRepo: MockFilesSearchRepository = MockFilesSearchRepository(),
        nodeRep: MockNodeRepository = MockNodeRepository(),
        megaHandleRepo: MockMEGAHandleRepository = MockMEGAHandleRepository()
    ) -> FileProviderEnumeratorUseCase<MockFilesSearchRepository, MockNodeRepository, MockMEGAHandleRepository> {
        FileProviderEnumeratorUseCase(
            filesSearchRepo: filesSearchRepo,
            nodeRepo: nodeRep,
            megaHandleRepo: megaHandleRepo)
    }
}
