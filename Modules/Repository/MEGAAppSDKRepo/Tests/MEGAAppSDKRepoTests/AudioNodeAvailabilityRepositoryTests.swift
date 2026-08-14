import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class AudioNodeAvailabilityRepositoryTests: XCTestCase {

    func testIsTakenDown_whenDownloadURLSucceeds_returnsFalse() async throws {
        let sut = makeSUT(accountError: .apiOk)

        let isTakenDown = try await sut.isTakenDown(.account(node()))

        XCTAssertFalse(isTakenDown)
    }

    func testIsTakenDown_whenDownloadURLIsBlocked_returnsTrue() async throws {
        let sut = makeSUT(accountError: .apiEBlocked)

        let isTakenDown = try await sut.isTakenDown(.account(node()))

        XCTAssertTrue(isTakenDown)
    }

    /// Any other failure is inconclusive, not a verdict — it must surface so the
    /// caller can decide, rather than being reported as "available".
    func testIsTakenDown_whenDownloadURLFailsForAnotherReason_throws() async {
        let sut = makeSUT(accountError: .apiEAccess)

        do {
            _ = try await sut.isTakenDown(.account(node()))
            XCTFail("Expected the underlying error to be rethrown")
        } catch {
            XCTAssertEqual((error as? MEGAError)?.type, .apiEAccess)
        }
    }

    func testIsTakenDown_forFileLink_probesTheAccountSDK() async throws {
        // Only the account SDK reports a block, so a `true` here proves which
        // SDK was asked.
        let sut = makeSUT(accountError: .apiEBlocked, folderError: .apiOk)

        let isTakenDown = try await sut.isTakenDown(.fileLink(node()))

        XCTAssertTrue(isTakenDown)
    }

    func testIsTakenDown_forFolderLink_probesTheFolderLinkSDK() async throws {
        // Folder-link nodes live in their own tree, so the account SDK must not be
        // the one answering: it says "available" while the folder SDK says "blocked".
        let sut = makeSUT(accountError: .apiOk, folderError: .apiEBlocked)

        let isTakenDown = try await sut.isTakenDown(.folderLink(node()))

        XCTAssertTrue(isTakenDown)
    }

    func testIsTakenDown_forFolderLink_isNotAnsweredByTheAccountSDK() async throws {
        // The mirror image of the previous test, so neither can pass by accident.
        let sut = makeSUT(accountError: .apiEBlocked, folderError: .apiOk)

        let isTakenDown = try await sut.isTakenDown(.folderLink(node()))

        XCTAssertFalse(isTakenDown)
    }

    /// A node the SDK cannot resolve is not a takedown — URL resolution reports
    /// that case as unplayable on its own, so nothing is thrown here.
    func testIsTakenDown_whenNodeCannotBeResolved_returnsFalse() async throws {
        let sut = AudioNodeAvailabilityRepository(
            sdk: MockSdk(megaSetError: .apiEBlocked),
            folderSDK: MockFolderSdk(errorType: .apiEBlocked)
        )

        let isTakenDown = try await sut.isTakenDown(.account(UnresolvableNode(handle: 42)))

        XCTAssertFalse(isTakenDown)
    }

    // MARK: - Helpers

    private func node(handle: MEGAHandle = 1) -> MockNode {
        MockNode(handle: handle)
    }

    private func makeSUT(
        accountError: MEGAErrorType = .apiOk,
        folderError: MEGAErrorType = .apiOk
    ) -> AudioNodeAvailabilityRepository {
        AudioNodeAvailabilityRepository(
            sdk: MockSdk(megaSetError: accountError),
            folderSDK: MockFolderSdk(errorType: folderError)
        )
    }
}

/// A `PlayableNode` that is not a `MEGANode`, so the repository has to fall back
/// to a tree lookup — which the mocks cannot satisfy.
private struct UnresolvableNode: PlayableNode {
    let handle: UInt64
    var name: String? { nil }
    var parentHandle: UInt64 { 0 }
    var fingerprint: String? { nil }
}
