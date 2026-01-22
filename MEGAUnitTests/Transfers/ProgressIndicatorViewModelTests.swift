@testable import MEGA
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("ProgressIndicatorViewModel Tests")
@MainActor
struct ProgressIndicatorViewModelTests {
    
    // MARK: - Helper Methods
    
    private static func waitForViewModelUpdate() async {
        for _ in 0..<5 {
            await Task.yield()
        }
    }
    
    private static func createDownloadTransfer(
        nodeHandle: UInt64 = 0,
        tag: Int = 0,
        transferredBytes: Int = 0,
        totalBytes: Int = 0,
        deltaSize: Int? = nil,
        state: TransferStateEntity = .active,
        lastErrorExtended: TransferErrorEntity? = nil
    ) -> TransferEntity {
        TransferEntity(
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            nodeHandle: nodeHandle,
            parentHandle: 0,
            tag: tag,
            deltaSize: deltaSize,
            lastErrorExtended: lastErrorExtended,
            state: state
        )
    }
    
    private static func createUploadTransfer(
        nodeHandle: UInt64 = 0,
        tag: Int = 0,
        transferredBytes: Int = 0,
        totalBytes: Int = 0,
        deltaSize: Int? = nil,
        state: TransferStateEntity = .active,
        lastErrorExtended: TransferErrorEntity? = nil
    ) -> TransferEntity {
        TransferEntity(
            type: .upload,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            nodeHandle: nodeHandle,
            parentHandle: 0,
            tag: tag,
            deltaSize: deltaSize,
            lastErrorExtended: lastErrorExtended,
            state: state
        )
    }
    
    private static func makeSUT() -> (sut: ProgressIndicatorViewModel, mockUseCase: MockTransferCounterUseCase) {
        let mockUseCase = MockTransferCounterUseCase()
        let sut = ProgressIndicatorViewModel(
            transferCounterUseCase: mockUseCase,
            accountStorageUseCase: MockAccountStorageUseCase()
        )
        return (sut, mockUseCase)
    }
    
    // MARK: - Initial State Tests
    
    @Suite("Initial State")
    @MainActor
    struct InitialStateTests {
        
        @Test("Initial state should be zero")
        func initialState() {
            let (sut, _) = makeSUT()
            
            #expect(sut.completedBytes == 0)
            #expect(sut.totalBytes == 0)
            #expect(sut.uploadTransfers == 0)
            #expect(sut.progress == 0)
        }
        
        @Test("Published properties initial values")
        func publishedPropertiesInitialValues() {
            let (sut, _) = makeSUT()
            
            #expect(sut.progress == 0.0)
            #expect(sut.shouldShowOverquotaBadge == false)
            #expect(sut.isHidden == true)
            #expect(sut.shouldShowUploadImage == false)
            #expect(sut.badgeState == .none)
            #expect(sut.progressStrokeColor == TokenColors.Support.success.cgColor)
            #expect(sut.shouldDismissWidget == false)
        }
    }
    
    // MARK: - Progress Calculation Tests
    
    @Suite("Progress Calculation")
    @MainActor
    struct ProgressCalculationTests {
        
        @Test("Progress calculation with zero total bytes")
        func progressWithZeroTotalBytes() {
            let (sut, _) = makeSUT()
            
            #expect(sut.progress == 0, "Progress should be 0 when totalBytes is 0")
        }
        
        @Test("Progress calculation with valid bytes")
        func progressCalculation() async {
            let (sut, mockUseCase) = makeSUT()
            
            let transfer = createDownloadTransfer(transferredBytes: 250, totalBytes: 1000)
            
            await mockUseCase.triggerTransferStart(transfer)
            await waitForViewModelUpdate()
            
            let expectedProgress = CGFloat(250) / CGFloat(1000)
            #expect(sut.progress == expectedProgress, "Progress should be 0.25")
        }
        
        @Test("Progress calculation with completed bytes equal to total")
        func progressCompleted() async {
            let (sut, mockUseCase) = makeSUT()
            
            let transfer = createDownloadTransfer(transferredBytes: 1000, totalBytes: 1000)
            
            await mockUseCase.triggerTransferStart(transfer)
            await waitForViewModelUpdate()
            
            #expect(sut.progress == 1.0, "Progress should be 1.0 when completed equals total")
        }
        
        @Test("Progress calculation edge cases")
        func progressCalculationEdgeCases() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Test with very small numbers
            let smallTransfer = createDownloadTransfer(transferredBytes: 1, totalBytes: 100)
            await mockUseCase.triggerTransferStart(smallTransfer)
            await waitForViewModelUpdate()
            
            let expectedSmallProgress = CGFloat(1) / CGFloat(100)
            #expect(sut.progress == expectedSmallProgress)
            
            sut.reset()
            
            // Test with very large numbers
            let largeTransfer = createDownloadTransfer(transferredBytes: 999_999_999, totalBytes: 1_000_000_000)
            await mockUseCase.triggerTransferStart(largeTransfer)
            await waitForViewModelUpdate()
            
            let expectedLargeProgress = CGFloat(999_999_999) / CGFloat(1_000_000_000)
            #expect(sut.progress == expectedLargeProgress)
        }
    }
    
    // MARK: - Reset and State Management Tests
    
    @Suite("Reset and State Management")
    @MainActor
    struct ResetAndStateManagementTests {
        
        @Test("Reset functionality")
        func resetCounter() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Simulate some transfers first
            let uploadTransfer = createUploadTransfer(transferredBytes: 500, totalBytes: 1000)
            
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await waitForViewModelUpdate()
            
            // Verify values are set
            #expect(sut.completedBytes > 0)
            #expect(sut.totalBytes > 0)
            #expect(sut.uploadTransfers > 0)
            
            sut.reset()
            
            #expect(sut.completedBytes == 0)
            #expect(sut.totalBytes == 0)
            #expect(sut.uploadTransfers == 0)
        }
        
        @Test("Reset clears last failed transfer")
        func resetClearsLastFailedTransfer() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Set up a failed transfer
            let failedTransfer = createDownloadTransfer(state: .failed)
            await mockUseCase.triggerTransferFinish(failedTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.lastFailedTransfer != nil)
            
            sut.reset()
            
            #expect(sut.lastFailedTransfer == nil)
        }
        
        @Test("Widget visibility control")
        func widgetVisibilityControl() {
            let (sut, _) = makeSUT()
            
            // Initially hidden
            #expect(sut.isHidden == true)
            
            // Show widget
            sut.showWidgetIfNeeded()
            // Note: isHidden state depends on configureData() which needs transfers
            
            // Hide widget without forbidding
            sut.hideWidget(widgetForbidden: false)
            #expect(sut.isHidden == true)
            
            // Hide widget with forbidding
            sut.hideWidget(widgetForbidden: true)
            #expect(sut.isHidden == true)
            
            // Try to show when forbidden - should remain hidden
            sut.showWidgetIfNeeded()
            #expect(sut.isHidden == true)
        }
        
        @Test("Transfer pause request handling")
        func transferPauseRequestHandling() {
            let (sut, _) = makeSUT()
            
            #expect(sut.badgeState == .none)
            
            sut.handleTransferPauseRequest(flag: true)
            #expect(sut.badgeState == .paused)
            
            sut.handleTransferPauseRequest(flag: false)
            #expect(sut.badgeState == .none)
        }
    }
    
    // MARK: - Transfer Operations Tests
    
    @Suite("Transfer Operations")
    @MainActor
    struct TransferOperationsTests {
        
        @Test("Transfer start clears overquota badge for downloads")
        func transferStartClearsOverquotaBadgeForDownloads() async {
            let (sut, mockUseCase) = makeSUT()
            
            // First set overquota badge to true via temporary error
            let tempErrorTransfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(tempErrorTransfer, errorType: .quotaExceeded)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            
            // Now start a download transfer - should clear overquota badge
            let downloadTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 500)
            await mockUseCase.triggerTransferStart(downloadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == false)
            #expect(sut.progressStrokeColor == TokenColors.Support.success.cgColor)
        }
        
        @Test("Transfer start does not clear overquota badge for uploads")
        func transferStartDoesNotClearOverquotaBadgeForUploads() async {
            let (sut, mockUseCase) = makeSUT()
            
            // First set overquota badge to true via temporary error
            let tempErrorTransfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(tempErrorTransfer, errorType: .quotaExceeded)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            
            // Now start an upload transfer - should NOT clear overquota badge
            let uploadTransfer = createUploadTransfer(transferredBytes: 100, totalBytes: 500)
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            #expect(sut.uploadTransfers == 1)
        }
        
        @Test("Transfer start handling for upload")
        func transferStartUpload() async {
            let (sut, mockUseCase) = makeSUT()
            
            let uploadTransfer = createUploadTransfer(transferredBytes: 200, totalBytes: 600)
            
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 1)
            #expect(sut.completedBytes == 200)
            #expect(sut.totalBytes == 600)
        }
        
        @Test("Transfer start handling for download")
        func transferStartDownload() async {
            let (sut, mockUseCase) = makeSUT()
            
            let downloadTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 500)
            
            await mockUseCase.triggerTransferStart(downloadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 0) // Download doesn't increment upload counter
            #expect(sut.completedBytes == 100)
            #expect(sut.totalBytes == 500)
        }
        
        @Test("Multiple transfer starts")
        func multipleTransferStarts() async {
            let (sut, mockUseCase) = makeSUT()
            
            let downloadTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 500)
            
            let uploadTransfer = createUploadTransfer(transferredBytes: 200, totalBytes: 600)
            
            let anotherDownloadTransfer = createDownloadTransfer(transferredBytes: 50, totalBytes: 300)
            
            await mockUseCase.triggerTransferStart(downloadTransfer)
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await mockUseCase.triggerTransferStart(anotherDownloadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 1) // Only one upload
            #expect(sut.completedBytes == 350) // 100 + 200 + 50
            #expect(sut.totalBytes == 1400) // 500 + 600 + 300
        }
        
        @Test("Transfer update handling")
        func transferUpdate() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with initial completed bytes
            let initialTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 500)
            
            await mockUseCase.triggerTransferStart(initialTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 100)
            
            // Now trigger an update with delta size
            let updateTransfer = createDownloadTransfer(transferredBytes: 150, totalBytes: 500, deltaSize: 50)
            
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 150) // 100 + 50 delta
        }
        
        @Test("Upload transfer finish handling")
        func uploadTransferFinish() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with upload transfers
            let uploadTransfer1 = createUploadTransfer(nodeHandle: 1, tag: 1)
            let uploadTransfer2 = createUploadTransfer(nodeHandle: 2, tag: 2)
            
            await mockUseCase.triggerTransferStart(uploadTransfer1)
            await mockUseCase.triggerTransferStart(uploadTransfer2)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 2)
            
            // Finish one upload transfer
            let finishedTransfer = createUploadTransfer(nodeHandle: 1, tag: 1, state: .complete)
            
            await mockUseCase.triggerTransferFinish(finishedTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 1)
        }
        
        @Test("Transfer cancellation handling")
        func transferCancellation() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start a transfer
            let transfer = createDownloadTransfer(transferredBytes: 200, totalBytes: 1000)
            
            await mockUseCase.triggerTransferStart(transfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 200)
            #expect(sut.totalBytes == 1000)
            
            // Cancel the transfer with partial progress
            let cancelledTransfer = createDownloadTransfer(transferredBytes: 50, totalBytes: 1000, state: .cancelled)
            
            let cancelResponse = cancelledTransfer
            await mockUseCase.triggerTransferFinish(cancelResponse)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 150) // 200 - 50
            #expect(sut.totalBytes == 0) // 1000 - 1000
        }
        
        @Test("Complex workflow scenario")
        func complexWorkflowScenario() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start multiple transfers
            let downloadTransfer = createDownloadTransfer(nodeHandle: 1, tag: 1, transferredBytes: 100, totalBytes: 1000)
            let uploadTransfer = createUploadTransfer(nodeHandle: 2, tag: 2, transferredBytes: 50, totalBytes: 500)
            let anotherDownloadTransfer = createDownloadTransfer(nodeHandle: 3, tag: 3, transferredBytes: 200, totalBytes: 2000)
            
            await mockUseCase.triggerTransferStart(downloadTransfer)
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await mockUseCase.triggerTransferStart(anotherDownloadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 1)
            #expect(sut.completedBytes == 350) // 100 + 50 + 200
            #expect(sut.totalBytes == 3500) // 1000 + 500 + 2000
            
            // Update progress
            let updateTransfer = createDownloadTransfer(nodeHandle: 1, tag: 1, deltaSize: 100)
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 450) // 350 + 100
            
            // Finish upload transfer
            let finishedUpload = createUploadTransfer(nodeHandle: 2, tag: 2, state: .complete)
            await mockUseCase.triggerTransferFinish(finishedUpload)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 0)
            
            // Cancel a download transfer
            let cancelledDownload = createDownloadTransfer(nodeHandle: 3, tag: 3, transferredBytes: 50, totalBytes: 2000, state: .cancelled)
            await mockUseCase.triggerTransferFinish(cancelledDownload)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 400) // 450 - 50
            #expect(sut.totalBytes == 1500) // 3500 - 2000
            
            // Check final progress
            let expectedProgress = CGFloat(400) / CGFloat(1500)
            #expect(sut.progress == expectedProgress)
        }
        
        @Test("Upload transfer count decrements safely")
        func uploadTransferCountDecrementsafely() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with no uploads
            #expect(sut.uploadTransfers == 0)
            
            // Try to finish an upload when none are active
            let finishedUpload = createUploadTransfer(nodeHandle: 1, tag: 1, state: .complete)
            await mockUseCase.triggerTransferFinish(finishedUpload)
            await waitForViewModelUpdate()
            
            // Should remain at 0 and not underflow
            #expect(sut.uploadTransfers == 0)
            
            // Start an upload
            let uploadTransfer = createUploadTransfer(nodeHandle: 2, tag: 2)
            await mockUseCase.triggerTransferStart(uploadTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 1)
            
            // Finish it
            let finishedUpload2 = createUploadTransfer(nodeHandle: 2, tag: 2, state: .complete)
            await mockUseCase.triggerTransferFinish(finishedUpload2)
            await waitForViewModelUpdate()
            
            #expect(sut.uploadTransfers == 0)
        }
    }
    
    // MARK: - Badge State Tests
    
    @Suite("Badge State Management")
    @MainActor
    struct BadgeStateTests {
        
        @Test("updateStateBadge handles generic error")
        func updateStateBadgeGenericError() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Create a transfer with generic error
            let genericErrorTransfer = createDownloadTransfer(
                state: .failed,
                lastErrorExtended: .generic
            )
            
            await mockUseCase.triggerTransferFinish(genericErrorTransfer)
            await waitForViewModelUpdate()
            
            // Generic errors should not show any badge
            #expect(sut.shouldShowOverquotaBadge == false)
            #expect(sut.badgeState == .none)
        }
        
        @Test("handleFailedTransfer with overquota error")
        func handleFailedTransferOverquota() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start a transfer to get some progress
            let normalTransfer = createDownloadTransfer(transferredBytes: 500, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(normalTransfer)
            await waitForViewModelUpdate()
            
            // Create a failed transfer with overquota error
            let overquotaTransfer = createDownloadTransfer(
                state: .failed,
                lastErrorExtended: .overquota
            )
            
            await mockUseCase.triggerTransferFinish(overquotaTransfer)
            await waitForViewModelUpdate()
            
            // Trigger configureData to process completed transfers
            sut.configureData()
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            #expect(sut.progressStrokeColor == TokenColors.Support.warning.cgColor)
        }
        
        @Test("bindBadgeStateUpdates priority order")
        func bindBadgeStateUpdatesPriority() async {
            let (sut, _) = makeSUT()
            sut.handleTransferPauseRequest(flag: true)
            #expect(sut.badgeState == .paused)
        }
    }
    
    // MARK: - Transfer Update Tests
    
    @Suite("Transfer Update Handling")
    @MainActor 
    struct TransferUpdateTests {
        
        @Test("handleTransferUpdate with delta size")
        func handleTransferUpdateWithDeltaSize() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with some progress
            let initialTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(initialTransfer)
            await waitForViewModelUpdate()
            
            let initialCompletedBytes = sut.completedBytes
            
            // Update with delta
            let updateTransfer = createDownloadTransfer(deltaSize: 50)
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == initialCompletedBytes + 50)
        }
        
        @Test("handleTransferUpdate without delta size")
        func handleTransferUpdateWithoutDeltaSize() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with some progress
            let initialTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(initialTransfer)
            await waitForViewModelUpdate()
            
            let initialCompletedBytes = sut.completedBytes
            
            // Update without delta (nil delta size)
            let updateTransfer = createDownloadTransfer(deltaSize: nil)
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == initialCompletedBytes)
        }
        
        @Test("handleTransferUpdate with zero delta")
        func handleTransferUpdateWithZeroDelta() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Start with some progress
            let initialTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(initialTransfer)
            await waitForViewModelUpdate()
            
            let initialCompletedBytes = sut.completedBytes
            
            // Update with zero delta
            let updateTransfer = createDownloadTransfer(deltaSize: 0)
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == initialCompletedBytes)
        }
    }
    
    // MARK: - Transfer Temporary Error Tests
    
    @Suite("Transfer Temporary Error Handling")
    @MainActor
    struct TransferTemporaryErrorTests {
        
        @Test("handleTransferTemporaryErrorUpdate quota exceeded")
        func handleTransferTemporaryErrorUpdateQuotaExceeded() async {
            let (sut, mockUseCase) = makeSUT()
            
            #expect(sut.shouldShowOverquotaBadge == false)
            
            let transfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(transfer, errorType: .quotaExceeded)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            #expect(sut.progressStrokeColor == TokenColors.Support.warning.cgColor)
        }
        
        @Test("handleTransferTemporaryErrorUpdate not enough quota")
        func handleTransferTemporaryErrorUpdateNotEnoughQuota() async {
            let (sut, mockUseCase) = makeSUT()
            
            #expect(sut.shouldShowOverquotaBadge == false)
            
            let transfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(transfer, errorType: .notEnoughQuota)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            #expect(sut.progressStrokeColor == TokenColors.Support.warning.cgColor)
        }
        
        @Test("handleTransferTemporaryErrorUpdate other error type")
        func handleTransferTemporaryErrorUpdateOtherError() async {
            let (sut, mockUseCase) = makeSUT()
            
            // First set overquota to true
            let quotaTransfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(quotaTransfer, errorType: .quotaExceeded)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            
            // Then trigger a different error
            let otherTransfer = createDownloadTransfer()
            await mockUseCase.triggerTransferTemporaryError(otherTransfer, errorType: .ok)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == false)
            #expect(sut.progressStrokeColor == TokenColors.Support.success.cgColor)
        }
    }
    
    // MARK: - setupTransferMonitoring Tests
    
    @Suite("setupTransferMonitoring")
    @MainActor
    struct SetupTransferMonitoringTests {
        
        @Test("setupTransferMonitoring handles all transfer events")
        func setupTransferMonitoringHandlesAllEvents() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Test that all event handlers work through setupTransferMonitoring
            
            // 1. Transfer start
            let startTransfer = createDownloadTransfer(transferredBytes: 100, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(startTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 100)
            #expect(sut.totalBytes == 1000)
            
            // 2. Transfer update
            let updateTransfer = createDownloadTransfer(deltaSize: 50)
            await mockUseCase.triggerTransferUpdate(updateTransfer)
            await waitForViewModelUpdate()
            
            #expect(sut.completedBytes == 150)
            
            // 3. Transfer temporary error
            await mockUseCase.triggerTransferTemporaryError(startTransfer, errorType: .quotaExceeded)
            await waitForViewModelUpdate()
            
            #expect(sut.shouldShowOverquotaBadge == true)
            
            // 4. Transfer finish
            let finishTransfer = createDownloadTransfer(state: .complete)
            await mockUseCase.triggerTransferFinish(finishTransfer)
            await waitForViewModelUpdate()
            
            // The finish should trigger configureData which may change state
            // We mainly want to ensure no crashes occur and basic functionality works
            #expect(sut.completedBytes >= 0) // Basic sanity check
        }
    }
    
    // MARK: - updateForCompletedTransfer Tests
    
    @Suite("updateForCompletedTransfer")
    @MainActor
    struct UpdateForCompletedTransferTests {
        
        @Test("updateForCompletedTransfers with failed transfer")
        func updateForCompletedTransfersWithFailedTransfer() async {
            let (sut, mockUseCase) = makeSUT()
            
            // Complete a transfer first to have totalBytes = completedBytes
            let completeTransfer = createDownloadTransfer(transferredBytes: 1000, totalBytes: 1000)
            await mockUseCase.triggerTransferStart(completeTransfer)
            await waitForViewModelUpdate()
            
            // Add a failed transfer
            let failedTransfer = createDownloadTransfer(
                state: .failed,
                lastErrorExtended: .overquota
            )
            await mockUseCase.triggerTransferFinish(failedTransfer)
            await waitForViewModelUpdate()
            
            // Now trigger configureData to process completed transfers
            sut.configureData()
            await waitForViewModelUpdate()
            
            // Should handle the failed transfer
            #expect(sut.shouldShowOverquotaBadge == true)
        }
    }
}
