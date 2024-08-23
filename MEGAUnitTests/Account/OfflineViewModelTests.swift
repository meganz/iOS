import Combine
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

@testable import MEGA

final class OfflineViewModelTests: XCTestCase {
    // MARK: - Helpers
    
    @MainActor
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
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000)
        return sut
    }
    
    private class MockMEGAStore: MEGAStore {}

    // MARK: - Tests

    @MainActor
    func testAction_onViewAppear_shouldReloadUIWhenNodeDownloadCompletionUpdatesAvaliable() async {
        // given
        let nodeTransferUseCase = MockNodeTransferUseCase()
        let sut = makeOfflineViewModelVMSut(transferUseCase: nodeTransferUseCase)
        
        let expectation = expectation(description: #function)
        var receivedCommand: OfflineViewModel.Command?
        
        sut.invokeCommand = {
            receivedCommand = $0
            expectation.fulfill()
        }
        
        // when
        sut.dispatch(.onViewAppear)
        
        nodeTransferUseCase.yield(TransferEntity(type: .download, nodeHandle: 1))
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        XCTAssertEqual(receivedCommand, .reloadUI)
    }
    
    @MainActor
    func testAction_onViewAppear_shouldNotReloadUIWhenNodeTransferIsNotDownload() async {
        // given
        let nodeTransferUseCase = MockNodeTransferUseCase()
        let sut = makeOfflineViewModelVMSut(transferUseCase: nodeTransferUseCase)
        
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        var receivedCommand: OfflineViewModel.Command?
        
        sut.invokeCommand = {
            receivedCommand = $0
            expectation.fulfill()
        }
        
        // when
        sut.dispatch(.onViewAppear)
        
        nodeTransferUseCase.yield(TransferEntity(type: .upload, nodeHandle: 1))
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        XCTAssertNil(receivedCommand)
    }

    @MainActor
    func testAction_onViewWillDisappear_shouldNotReceiveAnyCommands() async {
        // given
        let nodeTransferUseCase = MockNodeTransferUseCase()
        let sut = makeOfflineViewModelVMSut(transferUseCase: nodeTransferUseCase)
        
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        var receivedCommand: OfflineViewModel.Command?
        
        sut.invokeCommand = {
            receivedCommand = $0
            expectation.fulfill()
        }
        
        // when
        sut.dispatch(.onViewAppear)
        sut.dispatch(.onViewWillDisappear)
        
        nodeTransferUseCase.yield(TransferEntity(type: .download, nodeHandle: 1))
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        XCTAssertNil(receivedCommand)
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
