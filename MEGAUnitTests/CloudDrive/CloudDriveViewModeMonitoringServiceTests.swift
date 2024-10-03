@testable import MEGA
import MEGADomain
import XCTest

final class CloudDriveViewModeMonitoringServiceTests: XCTestCase {

    @MainActor
    func testListenToViewModesUpdate_fromListToThumbnail_shouldTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .thumbnail })
        await assertListenToViewModesUpdate(
            for: sut,
            node: NodeEntity(),
            currentViewMode: .list,
            expectedViewMode: .thumbnail
        )
    }

    @MainActor
    func testListenToViewModesUpdate_fromThumbnailToList_shouldTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .list })
        await assertListenToViewModesUpdate(
            for: sut,
            node: NodeEntity(),
            currentViewMode: .thumbnail,
            expectedViewMode: .list
        )
    }

    @MainActor
    func testListenToViewModesUpdate_fromListToList_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .list })
        await assertListenToViewModesUpdate(for: sut, node: NodeEntity(), currentViewMode: .list)
    }

    @MainActor
    func testListenToViewModesUpdate_fromThumbnailToThumbnail_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .thumbnail })
        await assertListenToViewModesUpdate(for: sut, node: NodeEntity(), currentViewMode: .thumbnail)
    }

    @MainActor
    func testListenToViewModesUpdate_fromThumbnailToMediaDiscovery_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .mediaDiscovery })
        await assertListenToViewModesUpdate(for: sut, node: NodeEntity(), currentViewMode: .thumbnail)
    }

    @MainActor
    func testListenToViewModesUpdate_fromListToMediaDiscovery_shouldNotTriggerAsyncStreamUpdate() async {
        let sut = makeSUT(viewModeProvider: { _ in .mediaDiscovery })
        await assertListenToViewModesUpdate(for: sut, node: NodeEntity(), currentViewMode: .list)
    }

    // MARK: - Private

    private typealias SUT = CloudDriveViewModeMonitoringService

    private func makeSUT(
        viewModeProvider: @escaping (NodeSource) async -> ViewModePreferenceEntity
    ) -> SUT {
        SUT(viewModeProvider: viewModeProvider)
    }

    @MainActor
    private func assertListenToViewModesUpdate(
        for sut: SUT,
        node: NodeEntity,
        currentViewMode: ViewModePreferenceEntity,
        expectedViewMode: ViewModePreferenceEntity? = nil
    ) async {
        let exp = expectation(description: "Wait for editing mode to be enabled")

        if expectedViewMode == nil {
            exp.expectedFulfillmentCount = 2
            exp.isInverted = true
        }

        let viewModeUpdatingTask = Task {
            if let expectedViewMode {
                for await viewMode in sut.updatedViewModes(
                    with: NodeSource.node { node },
                    currentViewMode: currentViewMode
                ) where viewMode == expectedViewMode {
                    exp.fulfill()
                }
            } else {
                for await _ in sut.updatedViewModes(
                    with: NodeSource.node { node },
                    currentViewMode: currentViewMode
                ) {
                    exp.fulfill()
                }
            }
        }

        Task {
            NotificationCenter.default.post(name: .MEGAViewModePreferenceDidChange, object: nil)
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        viewModeUpdatingTask.cancel()
    }
}
