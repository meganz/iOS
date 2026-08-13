import MEGAAppPresentation
import XCTest

final class OfflineActionGuardTests: XCTestCase {

    /// The guard's closure is `@Sendable`, so the counter cannot be a captured local var
    private final class PromptSpy: @unchecked Sendable {
        private(set) var callCount = 0
        private let isReachable: Bool

        init(isReachable: Bool) { self.isReachable = isReachable }

        func prompt() -> Bool {
            callCount += 1
            return isReachable
        }
    }

    func testAllowsActionRequiringConnection_whenNewOfflineModeDisabled_allowsWithoutPrompting() {
        let spy = PromptSpy(isReachable: false)
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: false, isReachablePromptingIfNot: spy.prompt)

        XCTAssertTrue(sut.allowsActionRequiringConnection())
        XCTAssertEqual(spy.callCount, 0, "the flag being off must not change behaviour at all")
    }

    func testAllowsActionRequiringConnection_whenEnabledAndReachable_allows() {
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true, isReachablePromptingIfNot: { true })

        XCTAssertTrue(sut.allowsActionRequiringConnection())
    }

    func testAllowsActionRequiringConnection_whenEnabledAndOffline_blocks() {
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true, isReachablePromptingIfNot: { false })

        XCTAssertFalse(sut.allowsActionRequiringConnection())
    }

    func testAllowsActionRequiringConnection_whenEnabled_asksTheReachabilityPromptEveryTime() {
        let spy = PromptSpy(isReachable: false)
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true, isReachablePromptingIfNot: spy.prompt)

        _ = sut.allowsActionRequiringConnection()
        _ = sut.allowsActionRequiringConnection()

        // The prompt is what the user sees, so every blocked tap must trigger it
        XCTAssertEqual(spy.callCount, 2)
    }

    func testNeverBlocking_allows() {
        XCTAssertTrue(OfflineActionGuard.neverBlocking.allowsActionRequiringConnection())
    }

    // MARK: - The prompt the app registers at launch

    /// The registration is process-global, so borrow it for the current test only and hand back
    /// whatever was there before. Restoring per test keeps these cases independent of the order
    /// they run in — one of them asserts on the unregistered default, which any leak would break.
    private func register(_ prompt: @escaping @Sendable () -> Bool) {
        let previous = DIContainer.isReachablePromptingIfNot
        DIContainer.isReachablePromptingIfNot = prompt
        addTeardownBlock { DIContainer.isReachablePromptingIfNot = previous }
    }

    func testAllowsActionRequiringConnection_withoutAnExplicitPrompt_usesTheRegisteredOne() {
        register { false }
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true)

        XCTAssertFalse(sut.allowsActionRequiringConnection())
    }

    func testAllowsActionRequiringConnection_readsTheRegisteredPromptWhenTheActionRuns() {
        // A guard can be built before the app has finished registering its prompt, so resolving
        // it at construction time would silently leave that screen unguarded
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true)
        register { false }

        XCTAssertFalse(sut.allowsActionRequiringConnection())
    }

    func testAllowsActionRequiringConnection_withNothingRegistered_allows() {
        let sut = OfflineActionGuard(isNewOfflineModeEnabled: true)

        XCTAssertTrue(
            sut.allowsActionRequiringConnection(),
            "a target that registers no prompt must behave as it did before offline mode existed"
        )
    }
}
