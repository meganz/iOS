@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

@Suite("NodeDataRepositoryTests")
struct NodeDataRepositoryTests {

    @Suite("Folder link info")
    struct NodeFolderLinkInfo {
        let sampleFolderLink = "https://mega.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A"
        
        @Test("Should return FolderLinkInfoEntity on successful request")
        func folderLinkInfoWithSuccessRequest() async throws {
            let mockRequest = MockRequest(
                handle: HandleEntity(1),
                text: "Sample",
                parentHandle: HandleEntity(2),
                folderInfo: MockFolderInfo()
            )
            let sut = makeSUT(
                sdk: MockSdk(requestResult: .success(mockRequest))
            )
            
            let result = try await sut.folderLinkInfo(sampleFolderLink)
            
            #expect(result == mockRequest.toFolderLinkInfoEntity())
        }
        
        @Test("Should throw error on failed request")
        func folderLinkInfoWithFailedRequest() async {
            let sut = makeSUT(
                sdk: MockSdk(requestResult: .failure(MockError.failingError))
            )
            
            await #expect(throws: FolderInfoErrorEntity.self) {
                _ = try await sut.folderLinkInfo(sampleFolderLink)
            }
        }
    }

    @Suite("Size for node")
    struct SizeForNode {
        private let folderHandle = HandleEntity(42)

        private func folder() -> MockNode {
            MockNode(handle: folderHandle, name: "Folder", nodeType: .folder)
        }

        @Test("Sizes a folder that only the folder link SDK knows about with that same SDK")
        func sizesFolderLinkFolderWithSharedFolderSdk() {
            let sut = makeSUT(
                sdk: MockSdk(),
                sharedFolderSdk: MockSdk(nodes: [folder()], nodeSizes: [folderHandle: 999])
            )

            // Asking the logged in account's SDK for a folder link node's size reports nothing, so a
            // regression here shows up as 0 rather than as a missing value.
            #expect(sut.sizeForNode(handle: folderHandle) == 999)
        }

        @Test("Sizes a folder of the logged in account with the account's own SDK")
        func sizesAccountFolderWithAccountSdk() {
            let sut = makeSUT(
                sdk: MockSdk(nodes: [folder()], nodeSizes: [folderHandle: 500]),
                sharedFolderSdk: MockSdk(nodes: [folder()], nodeSizes: [folderHandle: 999])
            )

            #expect(sut.sizeForNode(handle: folderHandle) == 500)
        }

        @Test("Returns nil when neither SDK knows the node")
        func returnsNilForUnknownNode() {
            let sut = makeSUT(sdk: MockSdk(), sharedFolderSdk: MockSdk())

            #expect(sut.sizeForNode(handle: folderHandle) == nil)
        }
    }

    private static func makeSUT(
        sdk: MEGASdk = MockSdk(),
        sharedFolderSdk: MEGASdk = MockSdk()
    ) -> NodeDataRepository {
        NodeDataRepository(sdk: sdk, sharedFolderSdk: sharedFolderSdk)
    }
}
