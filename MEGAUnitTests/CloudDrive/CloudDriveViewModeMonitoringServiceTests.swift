import ConcurrencyExtras
@testable import MEGA
import MEGADomain
import XCTest

final class CloudDriveViewModeMonitoringServiceTests: XCTestCase {

    func testListenToViewModesUpdate_fromListToThumbnail_shouldTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .list, viewModeProvider: { _ in .thumbnail })
        await assertListenToViewModesUpdate(for: sut, expectedViewMode: .thumbnail)
    }

    func testListenToViewModesUpdate_fromThumbnailToList_shouldTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .thumbnail, viewModeProvider: { _ in .list })
        await assertListenToViewModesUpdate(for: sut, expectedViewMode: .list)
    }

    func testListenToViewModesUpdate_fromListToList_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .list, viewModeProvider: { _ in .list })
        await assertListenToViewModesUpdate(for: sut)
    }

    func testListenToViewModesUpdate_fromThumbnailToThumbnail_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .thumbnail, viewModeProvider: { _ in .thumbnail })
        await assertListenToViewModesUpdate(for: sut)
    }

    func testListenToViewModesUpdate_fromThumbnailToMediaDiscovery_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .thumbnail, viewModeProvider: { _ in .mediaDiscovery })
        await assertListenToViewModesUpdate(for: sut)
    }

    func testListenToViewModesUpdate_fromListToMediaDiscovery_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(node: NodeEntity(), currentViewMode: .list, viewModeProvider: { _ in .mediaDiscovery })
        await assertListenToViewModesUpdate(for: sut)
    }

    // MARK: - Private

    private typealias SUT = CloudDriveViewModeMonitoringService

    private func makeSUT(
        node: NodeEntity,
        currentViewMode: ViewModePreferenceEntity,
        viewModeProvider: @escaping (NodeSource) async -> ViewModePreferenceEntity
    ) -> SUT {
        SUT(
            nodeSource: NodeSource.node { node },
            currentViewMode: currentViewMode,
            viewModeProvider: viewModeProvider
        )
    }

    private func assertListenToViewModesUpdate(for sut: SUT, expectedViewMode: ViewModePreferenceEntity? = nil) async {
        await withMainSerialExecutor {
            let exp = expectation(description: "Wait for editing mode to be enabled")

            if expectedViewMode == nil {
                exp.expectedFulfillmentCount = 2
                exp.isInverted = true
            }

            let viewModeUpdatingTask = Task {
                if let expectedViewMode {
                    for await viewMode in sut.viewModes where viewMode == expectedViewMode {
                        exp.fulfill()
                    }
                } else {
                    for await _ in sut.viewModes {
                        exp.fulfill()
                    }
                }
            }
            await Task.megaYield()
            NotificationCenter.default.post(name: .MEGAViewModePreferenceDidChange, object: nil)
            await fulfillment(of: [exp], timeout: 1.0)
            viewModeUpdatingTask.cancel()
        }
    }
}
