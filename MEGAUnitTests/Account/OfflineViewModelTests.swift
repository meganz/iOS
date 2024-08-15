import Combine
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

@testable import MEGA

final class OfflineViewModelTests: XCTestCase {

    // MARK: - Helpers
    
    private class MockMEGAStore: MEGAStore {}

    private func makeOfflineViewModelVMSut(
        transferUseCase: NodeTransferUseCaseProtocol = MockNodeTransferUseCase(),
        offlineUseCase: OfflineUseCaseProtocol = MockOfflineUseCase(),
        megaStore: MEGAStore = MockMEGAStore(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> OfflineViewModel {
        let sut = OfflineViewModel(
            transferUseCase: transferUseCase,
            offlineUseCase: offlineUseCase,
            megaStore: megaStore
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

    // MARK: - Tests

    @MainActor
    func testAction_addSubscriptions_shouldReceiveReloadUIInCaseOfTransferResultSuccess() {
        let sut = makeOfflineViewModelVMSut(
            transferUseCase: MockNodeTransferUseCase(
                _transferResult: .success(
                    .init()
                )
            )
        )
        test(
            viewModel: sut,
            action: OfflineViewAction.addSubscriptions,
            expectedCommands: [.reloadUI]
        )
    }

    @MainActor
    func testAction_removeSubscriptions_shouldNotReceiveAnyCommands() {
        let sut = makeOfflineViewModelVMSut()

        test(
            viewModel: sut,
            action: OfflineViewAction.removeSubscriptions,
            expectedCommands: []
        )
    }

    @MainActor
    func testAction_removeOfflineItems_shouldReceiveReloadUI() {
        let sut = makeOfflineViewModelVMSut()
        let mockItems: [URL] = []
        test(
            viewModel: sut,
            action: OfflineViewAction.removeOfflineItems(mockItems),
            expectedCommands: [.reloadUI]
        )
    }
}
