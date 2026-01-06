import FolderLink
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

struct FolderLinkFlowUseCaseTests {
    @Suite("Initial Start Flow")
    struct InitialStartFlowTests {
        @Test("Initial start flow: logs in with original link, fetches nodes, returns root")
        func initialStartFlow_success() async throws {
            let originalLink = "some_link"
            let folderLinkSearchUseCase = MockFolderLinkSearchUseCase(root: 123)
            let folderLinkLoginUseCase = MockFolderLinkLoginUseCase(loginResult: .success)
            let folderLinkFetchNodesUseCase = MockFolderLinkFetchNodeUseCase(fetchResult: .success)
            let folderLinkBuilder = MockFolderlinkBuilder()
            let sut = makeSUT(
                folderLinkLoginUseCase: folderLinkLoginUseCase,
                folderLinkFetchNodesUseCase: folderLinkFetchNodesUseCase,
                folderLinkSearchUseCase: folderLinkSearchUseCase,
                folderLinkBuilder: folderLinkBuilder
            )
            
            let root = try await sut.initialStart(with: originalLink)
            
            #expect(folderLinkBuilder.buildCalled == false)
            #expect(folderLinkLoginUseCase.loggedInLink == originalLink)
            #expect(folderLinkFetchNodesUseCase.fetchCalled == true)
            #expect(root == 123)
        }
        
        @Test(
            "When login throws error, should rethrow expected error",
            arguments: [
                (FolderLinkLoginErrorEntity.invalidDecryptionKey, FolderLinkFlowErrorEntity.linkUnavailable(.generic)),
                (FolderLinkLoginErrorEntity.missingDecryptionKey, FolderLinkFlowErrorEntity.missingDecryptionKey),
                (FolderLinkLoginErrorEntity.linkUnavailable(.generic), FolderLinkFlowErrorEntity.linkUnavailable(.generic))
            ]
        )
        func initialStart_loginThrows_rethrowsError(loginError: FolderLinkLoginErrorEntity, thrownError: FolderLinkFlowErrorEntity) async {
            let folderLinkLoginUseCase = MockFolderLinkLoginUseCase(loginResult: .failure(loginError))
            let sut = makeSUT(folderLinkLoginUseCase: folderLinkLoginUseCase)

            await #expect(throws: thrownError) {
                _ = try await sut.initialStart(with: "some_link")
            }
        }
        
        @Test(
            "When fetchNodes throws error, should rethrow expected error",
            arguments: [
                (FolderLinkFetchNodesErrorEntity.invalidDecryptionKey, FolderLinkFlowErrorEntity.linkUnavailable(.generic)),
                (FolderLinkFetchNodesErrorEntity.missingDecryptionKey, FolderLinkFlowErrorEntity.missingDecryptionKey),
                (FolderLinkFetchNodesErrorEntity.linkUnavailable(.generic), FolderLinkFlowErrorEntity.linkUnavailable(.generic))
            ]
        )
        func initialStart_fetchNodesThrows_rethrowsError(fetchNodesError: FolderLinkFetchNodesErrorEntity, thrownError: FolderLinkFlowErrorEntity) async {
            let folderLinkFetchNodesUseCase = MockFolderLinkFetchNodeUseCase(fetchResult: .failure(fetchNodesError))
            let sut = makeSUT(folderLinkFetchNodesUseCase: folderLinkFetchNodesUseCase)

            await #expect(throws: thrownError) {
                _ = try await sut.initialStart(with: "some_link")
            }
        }
    }
    
    @Suite("Initial Start Flow")
    struct ConfirmDecryptionKeyFlowTests {
        @Test("with decryption key: uses builder, logs in with built link, fetches nodes, returns root")
        func confirmDecryptionKey_success() async throws {
            let decryptionKey = "abc"
            let expectedRoot: HandleEntity = 999
            let originalLink = "some_link"
            let builtLink = "built_link"
            let folderLinkSearchUseCase = MockFolderLinkSearchUseCase(root: expectedRoot)
            let folderLinkLoginUseCase = MockFolderLinkLoginUseCase(loginResult: .success)
            let folderLinkFetchNodesUseCase = MockFolderLinkFetchNodeUseCase(fetchResult: .success)
            let folderLinkBuilder = MockFolderlinkBuilder(result: builtLink)
            
            let sut = makeSUT(
                folderLinkLoginUseCase: folderLinkLoginUseCase,
                folderLinkFetchNodesUseCase: folderLinkFetchNodesUseCase,
                folderLinkSearchUseCase: folderLinkSearchUseCase,
                folderLinkBuilder: folderLinkBuilder
            )
            
            let root = try await sut.confirmDecryptionKey(with: originalLink, decryptionKey: decryptionKey)
            
            #expect(folderLinkBuilder.buildCalled == true)
            #expect(folderLinkBuilder.link == originalLink)
            #expect(folderLinkBuilder.key == decryptionKey)
            #expect(folderLinkLoginUseCase.loggedInLink == builtLink)
            #expect(folderLinkFetchNodesUseCase.fetchCalled == true)
            #expect(root == expectedRoot)
        }
        
        @Test(
            "When login throws error, should rethrow expected error",
            arguments: [
                (FolderLinkLoginErrorEntity.invalidDecryptionKey, FolderLinkFlowErrorEntity.invalidDecryptionKey),
                (FolderLinkLoginErrorEntity.missingDecryptionKey, FolderLinkFlowErrorEntity.missingDecryptionKey),
                (FolderLinkLoginErrorEntity.linkUnavailable(.generic), FolderLinkFlowErrorEntity.linkUnavailable(.generic))
            ]
        )
        func confirmDecryptionKey_loginThrows_rethrowsError(loginError: FolderLinkLoginErrorEntity, thrownError: FolderLinkFlowErrorEntity) async {
            let folderLinkLoginUseCase = MockFolderLinkLoginUseCase(loginResult: .failure(loginError))
            let sut = makeSUT(folderLinkLoginUseCase: folderLinkLoginUseCase)

            await #expect(throws: thrownError) {
                _ = try await sut.confirmDecryptionKey(with: "some_link", decryptionKey: "some_key")
            }
        }
        
        @Test(
            "When fetchNodes throws error, should rethrow expected error",
            arguments: [
                (FolderLinkFetchNodesErrorEntity.invalidDecryptionKey, FolderLinkFlowErrorEntity.invalidDecryptionKey),
                (FolderLinkFetchNodesErrorEntity.missingDecryptionKey, FolderLinkFlowErrorEntity.missingDecryptionKey),
                (FolderLinkFetchNodesErrorEntity.linkUnavailable(.generic), FolderLinkFlowErrorEntity.linkUnavailable(.generic))
            ]
        )
        func confirmDecryptionKey_fetchNodesThrows_rethrowsError(fetchNodesError: FolderLinkFetchNodesErrorEntity, thrownError: FolderLinkFlowErrorEntity) async {
            let folderLinkFetchNodesUseCase = MockFolderLinkFetchNodeUseCase(fetchResult: .failure(fetchNodesError))
            let sut = makeSUT(folderLinkFetchNodesUseCase: folderLinkFetchNodesUseCase)

            await #expect(throws: thrownError) {
                _ = try await sut.confirmDecryptionKey(with: "some_link", decryptionKey: "some_key")
            }
        }
    }
    
    @Suite("Stop Flow")
    struct StopFlowTests {
        @Test("stop calls logout on logout use case")
        func stop_callsLogout() {
            let folderLinkLogoutUseCase = MockFolderLinkLogoutUseCase()
            let sut = makeSUT(folderLinkLogoutUseCase: folderLinkLogoutUseCase)
            sut.stop()
            #expect(folderLinkLogoutUseCase.logoutCalled == true)
        }
    }
    
    private static func makeSUT(
        folderLinkLoginUseCase: MockFolderLinkLoginUseCase = MockFolderLinkLoginUseCase(),
        folderLinkLogoutUseCase: MockFolderLinkLogoutUseCase = MockFolderLinkLogoutUseCase(),
        folderLinkFetchNodesUseCase: MockFolderLinkFetchNodeUseCase = MockFolderLinkFetchNodeUseCase(),
        folderLinkSearchUseCase: MockFolderLinkSearchUseCase = MockFolderLinkSearchUseCase(),
        folderLinkBuilder: MockFolderlinkBuilder = MockFolderlinkBuilder()
    ) -> FolderLinkFlowUseCase {
        FolderLinkFlowUseCase(
            folderLinkLoginUseCase: folderLinkLoginUseCase,
            folderLinkLogoutUseCase: folderLinkLogoutUseCase,
            folderLinkFetchNodesUseCase: folderLinkFetchNodesUseCase,
            folderLinkSearchUseCase: folderLinkSearchUseCase,
            folderLinkBuilder: folderLinkBuilder
        )
    }
}
