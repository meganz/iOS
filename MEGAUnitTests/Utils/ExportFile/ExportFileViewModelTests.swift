@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("ExportFileViewModel Tests Suite - Tests the behavior of ExportFileViewModel with different actions.")
struct ExportFileViewModelTestSuite {
    
    // MARK: - Helpers
    @MainActor
    private static func assertExport(
        action: ExportFileAction,
        expectedURLs: [URL]
    ) async {
        let (sut, router, _, analyticsUseCase, _) = makeSUT(urls: expectedURLs)
        
        sut.dispatch(action)
        
        await sut.currentTask?.value
        
        #expect(router.showProgressView_calledTimes == 1, "Expected showProgressView to be called once.")
        #expect(router.hideProgressView_calledTimes == 1, "Expected hideProgressView to be called once.")
        #expect(router.exportedFiles_calledTimes == 1, "Expected exportedFiles to be called once.")
        #expect(router.exportedUrls == expectedURLs, "Expected exported URLs to be \(expectedURLs) but got \(router.exportedUrls).")
        #expect(analyticsUseCase.type == .download(.exportFile), "Expected analytics event to be sent.")
    }
    
    @MainActor
    private static func makeSUT(
        urls: [URL] = [],
        isPaywalled: Bool = false
    ) -> (ExportFileViewModel, MockExportFileViewRouter, MockExportFileUseCase, MockAnalyticsEventUseCase, MockOverDiskQuotaChecker) {
        let router = MockExportFileViewRouter()
        let exportUseCase = MockExportFileUseCase(
            exportNodeResult: urls.first,
            exportNodesResult: urls,
            exportMessagesResult: urls,
            exportNodeFromMessageResult: urls.first
        )
        let analyticsUseCase = MockAnalyticsEventUseCase()
        let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
        let sut = ExportFileViewModel(
            router: router,
            analyticsEventUseCase: analyticsUseCase,
            exportFileUseCase: exportUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker
        )
        
        return (sut, router, exportUseCase, analyticsUseCase, overDiskQuotaChecker)
    }
    
    struct TestCaseData {
        let action: ExportFileAction
        let urls: [URL]
    }
    
    @Suite("File Export Tests - Verifies export works as expected.")
    struct FileExportTests {
        @Test(
            "Test export functionality for all scenarios",
            arguments: [
                // Scenario 1: Exporting a file from a single node
                TestCaseData(
                    action: .exportFileFromNode(NodeEntity()),
                    urls: [URL(string: "mock://file1")!]
                ),
                
                // Scenario 2: Exporting multiple files from multiple nodes
                TestCaseData(
                    action: .exportFilesFromNodes([NodeEntity(), NodeEntity()]),
                    urls: [URL(string: "mock://file1")!, URL(string: "mock://file2")!]
                ),
                
                // Scenario 3: Exporting files from chat messages
                TestCaseData(
                    action: .exportFilesFromMessages([ChatMessageEntity()], HandleEntity(123)),
                    urls: [URL(string: "mock://file1")!]
                ),
                
                // Scenario 4: Exporting file from node chat message
                TestCaseData(
                    action: .exportFileFromMessageNode(MEGANode(), HandleEntity(123), HandleEntity(234)),
                    urls: [URL(string: "mock://node1")!]
                )
            ]
        )
        func testExportFiles(with testCase: TestCaseData) async {
            await assertExport(
                action: testCase.action,
                expectedURLs: testCase.urls
            )
        }
        
        @Test("Over disk quota reached should not do anything",
              arguments: [
                ExportFileAction.exportFileFromNode(NodeEntity()),
                .exportFilesFromNodes([NodeEntity(), NodeEntity()]),
                .exportFilesFromMessages([ChatMessageEntity()], HandleEntity(123)),
                .exportFileFromMessageNode(MEGANode(), HandleEntity(123), HandleEntity(234))
              ]
        )
        @MainActor
        func overDiskQuota(action: ExportFileAction) async throws {
            let (sut, router, _, _, _) = makeSUT(isPaywalled: true)
            
            sut.dispatch(action)
            
            try await Task.sleep(nanoseconds: 100_000_000)
            
            #expect(router.showProgressView_calledTimes == 0, "Expected progress view should not be shown for action: \(action).")
        }
    }
    
    @Suite("Incomplete Download Tests - Verifies the warning is raised only when part of the selection failed to arrive.")
    struct IncompleteDownloadTests {
        @Test("fewer files than asked for are reported with both counts, and still exported")
        @MainActor
        func shortResult_warnsWithBothCountsAndExports() async {
            let urls = [URL(string: "mock://file1")!, URL(string: "mock://file2")!]
            let (sut, router, _, _, _) = makeSUT(urls: urls)

            sut.dispatch(.exportFilesFromNodes([NodeEntity(), NodeEntity(), NodeEntity()]))
            await sut.currentTask?.value

            #expect(router.warnDownloadIncompleteInvocations.count == 1)
            let invocation = router.warnDownloadIncompleteInvocations.first
            #expect(invocation?.downloadedCount == 2)
            #expect(invocation?.failedCount == 1)
            #expect(router.exportedUrls == urls, "The files that did arrive should still be exported.")
        }

        @Test("a complete result is exported without a warning")
        @MainActor
        func completeResult_doesNotWarn() async {
            let urls = [URL(string: "mock://file1")!, URL(string: "mock://file2")!]
            let (sut, router, _, _, _) = makeSUT(urls: urls)

            sut.dispatch(.exportFilesFromNodes([NodeEntity(), NodeEntity()]))
            await sut.currentTask?.value

            #expect(router.warnDownloadIncompleteInvocations.isEmpty)
            #expect(router.exportedFiles_calledTimes == 1)
        }

        /// The whole batch failing is the case most worth reporting, so it is warned about too — but with
        /// nothing to hand on there is no export to continue to.
        @Test("a result with nothing in it is still warned about, and exports nothing")
        @MainActor
        func emptyResult_warnsWithoutExporting() async {
            let (sut, router, _, _, _) = makeSUT(urls: [])

            sut.dispatch(.exportFilesFromNodes([NodeEntity(), NodeEntity()]))
            await sut.currentTask?.value

            #expect(router.warnDownloadIncompleteInvocations.count == 1)
            #expect(router.warnDownloadIncompleteInvocations.first?.downloadedCount == 0)
            #expect(router.warnDownloadIncompleteInvocations.first?.failedCount == 2)
            #expect(router.exportedFiles_calledTimes == 0)
        }

        /// The warning is awaited, which holds the export open for as long as it is on screen — long enough
        /// for the export to be called off. Whatever arrived then stays put rather than opening a share sheet
        /// nobody is waiting on.
        @Test("an export cancelled while the warning is on screen hands nothing over")
        @MainActor
        func cancelledDuringWarning_handsNothingOver() async {
            let (sut, router, _, _, _) = makeSUT(urls: [URL(string: "mock://file1")!])
            router.onWarnDownloadIncomplete = { sut.cancelCurrentTask() }

            sut.dispatch(.exportFilesFromNodes([NodeEntity(), NodeEntity()]))
            // Taken before the task body runs, because cancelling clears it.
            let task = sut.currentTask
            await task?.value

            #expect(router.warnDownloadIncompleteInvocations.count == 1, "The warning itself still belongs on screen.")
            #expect(router.exportedFiles_calledTimes == 0)
            #expect(router.hideProgressView_calledTimes == 1, "The progress view must not be left behind either.")
        }
    }

    // MARK: - Cancel Task Tests
    @Suite("Task Cancellation Tests - Verifies that cancelling an export task works as expected.")
    struct CancelTaskTests {
        @Test("Canceling the current task should stop the export and not return any files", arguments: [
            ExportFileAction.exportFileFromNode(NodeEntity()),
            ExportFileAction.exportFilesFromNodes([NodeEntity(), NodeEntity()]),
            ExportFileAction.exportFilesFromMessages([ChatMessageEntity()], HandleEntity(123)),
            ExportFileAction.exportFileFromMessageNode(MEGANode(), HandleEntity(123), HandleEntity(234))
        ])
        @MainActor
        func cancelCurrentTaskShouldStopExport(action: ExportFileAction) async {
            let (sut, router, exportUseCase, _, _) = makeSUT(urls: [URL(string: "mock://file1")!])
            
            sut.dispatch(action)
            sut.cancelCurrentTask()
            
            #expect(router.showProgressView_calledTimes == 1, "Expected progress view to be shown exactly once after starting export action: \(action).")
            #expect(router.exportedFiles_calledTimes == 0, "No files should be exported after the task was canceled for action: \(action).")
            #expect(exportUseCase.exportNode_calledTimes == 0, "Expected no node exports to be attempted after the export task was canceled for action: \(action).")
            #expect(exportUseCase.exportNodes_calledTimes == 0, "Expected no multiple node exports to be attempted after the export task was canceled for action: \(action).")
            #expect(exportUseCase.exportMessages_calledTimes == 0, "Expected no message exports to be attempted after the export task was canceled for action: \(action).")
            #expect(exportUseCase.exportNodeFromMessage_calledTimes == 0, "Expected no node export from messages to be attempted after the export task was canceled for action: \(action).")
        }
    }
}
