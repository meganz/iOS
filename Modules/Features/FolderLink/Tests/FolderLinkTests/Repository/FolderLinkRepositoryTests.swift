import FolderLink
import MEGAAppSDKRepoMock
import Testing

struct FolderLinkRepositoryTests {
    @Suite("Login to folder link tests")
    struct LoginTests {
        @Test func loginSucceeds() async throws {
            let sdk = MockSdk()
            sdk.loginToLinkRequestResult = .success
            let repo = FolderLinkRepository(sdk: sdk)
            
            await #expect(throws: Never.self) {
                try await repo.loginTo(link: "https://example.com/#F!abc")
            }
        }
        
        @Test("Login throws downETD when error linkStatus is downETD")
        func loginThrowsDownETD() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, linkStatus: .downETD)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.downETD)) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throws userETDSuspension when error userStatus etdSuspension")
        func loginThrowsUserETDSuspension() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .etdSuspension)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.userETDSuspension)) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throws copyrightSuspension when error userStatus copyrightSuspension")
        func loginThrowsCopyrightSuspension() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .copyrightSuspension)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.copyrightSuspension)) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throw generic when linkStatus and userStatus is not downETD, etdSuspension and copyrightSuspension ")
        func loginThrowsGeneric() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .suspendedAdminFullDisable)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.generic)) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throws invalidDecryptionKey when error is apiEArgs")
        func loginThrowsInvalidDecryptionKey() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEArgs, hasExtraInfo: false)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.invalidDecryptionKey) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throws missingDecryptionKey when error is apiEIncomplete")
        func loginThrowsMissingDecryptionKey() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEIncomplete, hasExtraInfo: false)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.missingDecryptionKey) {
                try await repo.loginTo(link: "link")
            }
        }
        
        @Test("Login throw generic when error is not apiEArgs and apiEIncomplete")
        func loginThrowsGenericForOtherErorrTypes() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEBlocked, hasExtraInfo: false)
            sdk.loginToLinkRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkLoginErrorEntity.linkUnavailable(.generic)) {
                try await repo.loginTo(link: "link")
            }
        }
    }

    @Suite("Fetch nodes tests")
    struct FetchNodesTests {
        @Test func fetchNodesSucceeds() async throws {
            let sdk = MockSdk()
            sdk.fetchNodesRequestResult = .success(MockRequest(handle: 0))
            let repo = FolderLinkRepository(sdk: sdk)
            
            await #expect(throws: Never.self) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws invalidDecryptionKey when request has flag")
        func fetchNodesThrowsInvalidDecryptionKeyWhenRequestHasFlag() async {
            let sdk = MockSdk()
            sdk.fetchNodesRequestResult = .success(MockRequest(handle: 0, flag: true))
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.invalidDecryptionKey) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws downETD when error linkStatus is downETD")
        func fetchNodesThrowDownETDWhenLinkStatusIsDownETD() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, linkStatus: .downETD)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.downETD)) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws userETDSuspension when error userStatus is etdSuspension")
        func fetchNodesThrowuserETDSuspensionWhenUserStatusIsDtdSuspension() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .etdSuspension)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.userETDSuspension)) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws copyrightSuspension when error userStatus is copyrightSuspension")
        func fetchNodesThrowusCopyrightSuspensionWhenUserStatusIsCopyrightSuspension() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .copyrightSuspension)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.copyrightSuspension)) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws generic when linkStatus or userStatus not downETD, etdSuspension and copyrightSuspension")
        func fetchNodesThrowusGeneric() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEInternal, hasExtraInfo: true, userStatus: .etdUnknown)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.generic)) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws missingDecryptionKey when error is apiEIncomplete")
        func fetchNodesThrowsMissingDecryptionKey() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEIncomplete, hasExtraInfo: false)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.missingDecryptionKey) {
                try await repo.fetchNodes()
            }
        }
        
        @Test("FetchNodes throws generic when error is not apiEIncomplete")
        func fetchNodesThrowsGeneric() async {
            let sdk = MockSdk()
            let error = MockError(errorType: .apiEAccess, hasExtraInfo: false)
            sdk.fetchNodesRequestResult = .failure(error)
            let repo = FolderLinkRepository(sdk: sdk)

            await #expect(throws: FolderLinkFetchNodesErrorEntity.linkUnavailable(.generic)) {
                try await repo.fetchNodes()
            }
        }
    }

    @Suite("getRootNode tests")
    struct GetRootNodeTests {
        @Test("getRootNode returns .invalid when root is nil")
        func getRootNode_nil_returnsInvalid() {
            let sdk = MockSdk(megaRootNode: nil)
            let repo = FolderLinkRepository(sdk: sdk)
            #expect(repo.getRootNode() == .invalid)
        }

        @Test("getRootNode returns root handle")
        func getRootNode_returnsHandle() {
            let sdk = MockSdk(megaRootNode: MockNode(handle: 999))
            let repo = FolderLinkRepository(sdk: sdk)
            #expect(repo.getRootNode() == 999)
        }
    }

    @Test("logout triggers sdk.logout")
    func logout() {
        let sdk = MockSdk()
        let repo = FolderLinkRepository(sdk: sdk)
        #expect(sdk.logoutCalled == false)
        repo.logout()
        #expect(sdk.logoutCalled == true)
    }

    @Suite("Get children for node tests")
    struct ChildrenOfNodeTests {
        @Test("children returns empty when node not found")
        func childrenReturnsEmptyWhenNodeNotFound() {
            let sdk = MockSdk(nodes: [])
            let repo = FolderLinkRepository(sdk: sdk)
            let children = repo.children(of: 1)
            #expect(children.isEmpty)
        }
        
        @Test("children returns nodes")
        func childrenReturnNodes() {
            let sdk = MockSdk(nodes: [
                MockNode(handle: 1),
                MockNode(handle: 2, parentHandle: 1),
                MockNode(handle: 3, parentHandle: 1),
                MockNode(handle: 4, parentHandle: 2),
            ])
            let repo = FolderLinkRepository(sdk: sdk)
            let children = repo.children(of: 1)
            #expect(children.map(\.handle) == [2, 3])
        }
    }
    
    @Suite("Node for handle Tests")
    struct NodeForHandleTests {
        @Test("node returns nil when not found")
        func nodeReturnsNilWhenNotFound() {
            let sdk = MockSdk(nodes: [
                MockNode(handle: 1),
                MockNode(handle: 2),
            ])
            let repo = FolderLinkRepository(sdk: sdk)

            #expect(repo.node(for: 3) == nil)
        }

        @Test("node returns mapped entity")
        func nodeReturnsMappedEntity() {
            let node = MockNode(handle: 123, hasThumbnail: true)
            let sdk = MockSdk(nodes: [node])
            let repo = FolderLinkRepository(sdk: sdk)
            let nodeEntity = repo.node(for: 123)
            #expect(nodeEntity?.handle == 123)
            #expect(nodeEntity?.hasThumbnail == true)
        }
    }

    // MARK: - retryPendingConnections
    @Test("retryPendingConnections triggers sdk call")
    func retryPendingConnections() {
        let sdk = MockSdk()
        let repo = FolderLinkRepository(sdk: sdk)
        repo.retryPendingConnections()
        #expect(sdk.retryPendingConnectionsCalled == true)
    }
}
