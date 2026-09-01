@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class AlbumLinkOfflineRouterTests: XCTestCase {

    @MainActor
    func testCopyToOffline_whenTheDeviceHasNoRoom_shouldWarnWithoutResolvingAnything() async {
        let nodeProvider = MockMEGANodeProvider(nodes: [])
        let alertRouter = MockNotEnoughStorageAlertRouter()
        let sut = AlbumLinkOfflineRouter(
            nodeProvider: nodeProvider,
            storageChecker: MockDeviceStorageChecker(
                verdict: .doesNotFit(requiredBytes: 100, availableBytes: 10)),
            notEnoughStorageAlertRouter: alertRouter)

        await sut.copyToOffline(photos: [NodeEntity(handle: 1, isFile: true, size: 100)])

        XCTAssertEqual(alertRouter.shownRequiredBytes, [100])
        XCTAssertEqual(alertRouter.shownAvailableBytes, [10])
        // Resolving a whole album costs a request per uncached photo, so the shortfall is settled first.
        XCTAssertEqual(nodeProvider.nodeForHandleCallCount, 0)
    }
}

private struct MockDeviceStorageChecker: DeviceStorageChecking {
    let verdict: DeviceStorageVerdict

    func verdict(forAdditionalBytes bytes: UInt64) async -> DeviceStorageVerdict {
        verdict
    }
}

@MainActor
private final class MockNotEnoughStorageAlertRouter: NotEnoughStorageAlertRouting {
    private(set) var shownRequiredBytes: [UInt64] = []
    private(set) var shownAvailableBytes: [UInt64] = []

    nonisolated init() {}

    func showNotEnoughStorage(requiredBytes: UInt64, availableBytes: UInt64) {
        shownRequiredBytes.append(requiredBytes)
        shownAvailableBytes.append(availableBytes)
    }
}
