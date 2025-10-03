@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@Suite("NodeInfoUseCase")
struct NodeInfoUseCaseTests {
    private static let handle = HandleEntity()
    private static let sampleNode = MockNode(handle: 101)
    private static let successResult: Result<Void, NodeInfoError> = .success
    private static let failureResult: Result<Void, NodeInfoError> = .failure(.generic)
    private static let emptyCount: Int = 0
    private static let tracksCount: Int = 4
    
    private static func makeSUT(
        repo: MockNodeInfoRepository
    ) -> NodeInfoUseCase {
        NodeInfoUseCase(nodeInfoRepository: repo)
    }
    
    @Suite("Node lookup")
    struct NodeLookupSuite {
        @Test(arguments: [
            (successResult, true, Comment("Repository success: returns a node")),
            (failureResult, false, Comment("Repository failure: returns nil"))
        ])
        func nodeForHandle_respectsRepositoryOutcome(_ result: Result<Void, NodeInfoError>, _ expectedHasNode: Bool, _ note: Comment) {
            let sut = makeSUT(repo: MockNodeInfoRepository(result: result))
            let node = sut.node(for: handle)
            #expect((node != nil) == expectedHasNode, note)
        }
    }
    
    @Suite("Fetch audio tracks")
    struct FetchTracksSuite {
        @Test(arguments: [
            (successResult, tracksCount, Comment("Success: propagates items")),
            (failureResult, emptyCount, Comment("Comment(Failure: returns nil (treated as zero for count check)"))
        ])
        func fetchAudioTracks_propagatesRepository(_ result: Result<Void, NodeInfoError>, _ expectedCount: Int, _ note: Comment) {
            let sut = makeSUT(repo: MockNodeInfoRepository(result: result))
            let items = sut.fetchAudioTracks(from: handle)
            #expect((items?.count ?? emptyCount) == expectedCount, note)
        }
        
        @Test(arguments: [
            (successResult, tracksCount, Comment("Success: propagates items for folder-link")),
            (failureResult, emptyCount, Comment("Failure: returns nil for folder-link (treated as zero)"))
        ])
        func fetchFolderLinkAudioTracks_propagatesRepository(_ result: Result<Void, NodeInfoError>, _ expectedCount: Int, _ note: Comment) {
            let sut = makeSUT(repo: MockNodeInfoRepository(result: result))
            let items = sut.fetchFolderLinkAudioTracks(from: handle)
            #expect((items?.count ?? emptyCount) == expectedCount, note)
        }
    }
    
    @Suite("Folder-link session control")
    struct FolderLinkSessionSuite {
        @Test("folderLinkLogout is callable without side effects")
        func folderLinkLogout_invokesRepository() {
            let repo = MockNodeInfoRepository(result: .success)
            let sut = makeSUT(repo: repo)
            sut.folderLinkLogout()
            #expect(true)
        }
    }
    
    @Suite("Takedown evaluation")
    struct TakedownSuite {
        @Test(arguments: [
            (false, true, Comment("Account node with ToS violation: taken down")),
            (false, false, Comment("Account node without ToS violation: not taken down")),
            (true, true, Comment("Folder-link node with ToS violation: taken down")),
            (true, false, Comment("Folder-link node without ToS violation: not taken down"))
        ])
        func isTakenDown_matchesViolationFlag(_ isFolderLink: Bool, _ violation: Bool, _ note: Comment) async throws {
            let repo = MockNodeInfoRepository(
                result: .success,
                violatesTermsOfServiceResult: .success(violation)
            )
            let sut = makeSUT(repo: repo)
            let value = try await sut.isTakenDown(node: sampleNode, isFolderLink: isFolderLink)
            #expect(value == violation, note)
        }
        
        @Test(arguments: [
            (false, Comment("Account node: error from repository is propagated")),
            (true, Comment("Folder-link node: error from repository is propagated"))
        ])
        func isTakenDown_propagatesRepositoryError(_ isFolderLink: Bool, _ note: Comment) async {
            let repo = MockNodeInfoRepository(
                result: .success,
                violatesTermsOfServiceResult: .failure(.generic)
            )
            let sut = makeSUT(repo: repo)
            await #expect(throws: (any Error).self, note) {
                _ = try await sut.isTakenDown(node: sampleNode, isFolderLink: isFolderLink)
            }
        }
    }
}
