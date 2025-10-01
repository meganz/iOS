@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@Suite("NodeInfoUseCase")
struct NodeInfoUseCaseTests {
    private static let successRepo = MockNodeInfoRepository(result: .success, violatesTermsOfServiceResult: .success(true))
    private static let failureRepo = MockNodeInfoRepository(result: .failure(.generic), violatesTermsOfServiceResult: .success(true))
    private static let anyHandle = HandleEntity()
    private static let anyNode = MockNode(handle: 1, name: "", isTakenDown: false)
    private static let expectedError = NodeInfoError.generic
    private static let tosTrueSUT = makeSUT(termsOfServiceViolationResult: .success(true))
    private static let tosFalseSUT = makeSUT(termsOfServiceViolationResult: .success(false))
    
    private static func mockURLs() throws -> [URL] {
        AudioPlayerItem.mockArray.compactMap(\.url)
    }
    
    private static func makeSUT(termsOfServiceViolationResult: Result<Bool, NodeInfoError>) -> NodeInfoUseCase {
        let repo = MockNodeInfoRepository(violatesTermsOfServiceResult: termsOfServiceViolationResult)
        return NodeInfoUseCase(nodeInfoRepository: repo)
    }
    
    @Suite("Retrieval")
    struct RetrievalSuite {
        @Test("node(fromHandle:) returns value only on success")
        func nodeFromHandle() {
            #expect(successRepo.node(fromHandle: anyHandle) != nil)
            #expect(failureRepo.node(fromHandle: anyHandle) == nil)
        }
        
        @Test("folderNode(fromHandle:) returns value only on success")
        func folderNodeFromHandle() {
            #expect(successRepo.folderNode(fromHandle: anyHandle) != nil)
            #expect(failureRepo.folderNode(fromHandle: anyHandle) == nil)
        }
        
        @Test("path(fromHandle:) returns value only on success")
        func pathFromHandle() {
            #expect(successRepo.path(fromHandle: anyHandle) != nil)
            #expect(failureRepo.path(fromHandle: anyHandle) == nil)
        }
    }
    
    @Suite("ChildrenInfo")
    struct ChildrenInfoSuite {
        @Test("childrenInfo(fromParentHandle:) matches mock urls on success, nil on failure")
        func parentChildren() throws {
            let children = try #require(successRepo.childrenInfo(fromParentHandle: anyHandle))
            let expected = try mockURLs()
            #expect(children.compactMap(\.url) == expected)
            #expect(failureRepo.childrenInfo(fromParentHandle: anyHandle) == nil)
        }
        
        @Test("folderChildrenInfo(fromParentHandle:) matches mock urls on success, nil on failure")
        func folderParentChildren() throws {
            let children = try #require(successRepo.folderChildrenInfo(fromParentHandle: anyHandle))
            let expected = try mockURLs()
            #expect(children.compactMap(\.url) == expected)
            #expect(failureRepo.folderChildrenInfo(fromParentHandle: anyHandle) == nil)
        }
        
        @Test("info(fromNodes:) matches mock urls on success, nil on failure")
        func infoFromNodes() throws {
            let info = try #require(successRepo.info(fromNodes: [MEGANode()]))
            let expected = try mockURLs()
            #expect(info.compactMap(\.url) == expected)
            #expect(failureRepo.info(fromNodes: [MEGANode()]) == nil)
        }
    }
    
    @Suite("TakenDown")
    struct TakenDownSuite {
        @Test(
            "isTakenDown returns expected value",
            arguments: [
                (isFolderLink: false, tos: true, expected: true, note: "Non-folder link with a TOS violation should return true"),
                (isFolderLink: true, tos: true, expected: true, note: "Folder link with a TOS violation should return true"),
                (isFolderLink: true, tos: false, expected: false, note: "Folder link without a TOS violation should return false")
            ]
        )
        func isTakenDownMatrix(isFolderLink: Bool, tos: Bool, expected: Bool, note: Comment) async throws {
            let sut = makeSUT(termsOfServiceViolationResult: .success(tos))
            let value = try await sut.isTakenDown(node: anyNode, isFolderLink: isFolderLink)
            #expect(value == expected, note)
        }
        
        @Test("folder link throws when repository errors")
        func folderLink_error_throws() async {
            let sut = makeSUT(termsOfServiceViolationResult: .failure(expectedError))
            do {
                _ = try await sut.isTakenDown(node: anyNode, isFolderLink: true)
                Issue.record("Expected throw")
            } catch {
                #expect((error as? NodeInfoError) == expectedError)
            }
        }
    }
}
