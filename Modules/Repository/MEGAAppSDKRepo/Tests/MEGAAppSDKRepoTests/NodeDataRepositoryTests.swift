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

    private static func makeSUT(
        sdk: MEGASdk = MockSdk(),
        sharedFolderSdk: MEGASdk = MockSdk()
    ) -> NodeDataRepository {
        NodeDataRepository(sdk: sdk, sharedFolderSdk: sdk)
    }
}
