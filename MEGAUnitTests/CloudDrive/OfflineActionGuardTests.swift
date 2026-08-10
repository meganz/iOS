@testable import MEGA
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
}
