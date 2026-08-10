import FileLink
import MEGAAppSDKRepoMock
import MEGASdk
import Testing

@Suite("FileLinkRepository Tests")
struct FileLinkRepositoryTests {
    @Test("resolving a link returns the public node it carries")
    func publicNode_success_returnsNode() async throws {
        let sut = makeSUT(result: .success(MockRequest(handle: 1, publicNode: MockNode(handle: 42))))

        let node = try await sut.publicNode(for: "link")

        #expect(node.handle == 42)
    }

    @Test("a request without a public node is an unavailable link")
    func publicNode_withoutNode_throwsGeneric() async {
        let sut = makeSUT(result: .success(MockRequest(handle: 1)))

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.generic)) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("a raised flag means the key in the link could not decrypt it")
    func publicNode_flagRaised_throwsInvalidDecryptionKey() async {
        let sut = makeSUT(result: .success(MockRequest(handle: 1, flag: true, publicNode: MockNode(handle: 42))))

        await #expect(throws: FileLinkPublicNodeErrorEntity.invalidDecryptionKey) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("bad arguments mean an invalid decryption key")
    func publicNode_apiEArgs_throwsInvalidDecryptionKey() async {
        let sut = makeSUT(result: .failure(MockError(errorType: .apiEArgs)))

        await #expect(throws: FileLinkPublicNodeErrorEntity.invalidDecryptionKey) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("an incomplete request means the link was shared without its key")
    func publicNode_apiEIncomplete_throwsMissingDecryptionKey() async {
        let sut = makeSUT(result: .failure(MockError(errorType: .apiEIncomplete)))

        await #expect(throws: FileLinkPublicNodeErrorEntity.missingDecryptionKey) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("an expired link keeps its own reason")
    func publicNode_apiEExpired_throwsExpired() async {
        let sut = makeSUT(result: .failure(MockError(errorType: .apiEExpired)))

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.expired)) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("a taken down link keeps its own reason")
    func publicNode_downETD_throwsDownETD() async {
        let sut = makeSUT(
            result: .failure(MockError(errorType: .apiEBlocked, hasExtraInfo: true, linkStatus: .downETD))
        )

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.downETD)) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("a suspended owner keeps its own reason")
    func publicNode_userETDSuspension_throwsUserETDSuspension() async {
        let sut = makeSUT(
            result: .failure(MockError(errorType: .apiEBlocked, hasExtraInfo: true, userStatus: .etdSuspension))
        )

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.userETDSuspension)) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("a copyright suspension keeps its own reason")
    func publicNode_copyrightSuspension_throwsCopyrightSuspension() async {
        let sut = makeSUT(
            result: .failure(MockError(errorType: .apiEBlocked, hasExtraInfo: true, userStatus: .copyrightSuspension))
        )

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.copyrightSuspension)) {
            try await sut.publicNode(for: "link")
        }
    }

    @Test("any other failure is a generic unavailable link")
    func publicNode_otherError_throwsGeneric() async {
        let sut = makeSUT(result: .failure(MockError(errorType: .apiENoent)))

        await #expect(throws: FileLinkPublicNodeErrorEntity.linkUnavailable(.generic)) {
            try await sut.publicNode(for: "link")
        }
    }

    private func makeSUT(result: Result<MEGARequest, MEGAError>) -> FileLinkRepository {
        let sdk = MockSdk()
        sdk.publicNodeForFileLinkRequestResult = result
        return FileLinkRepository(sdk: sdk)
    }
}
