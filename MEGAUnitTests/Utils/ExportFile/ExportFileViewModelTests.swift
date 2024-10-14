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
        let (sut, router, _, analyticsUseCase) = makeSUT(urls: expectedURLs)
        
        sut.dispatch(action)
        
        await sut.currentTask?.value
        
        #expect(router.showProgressView_calledTimes == 1, "Expected showProgressView to be called once.")
        #expect(router.hideProgressView_calledTimes == 1, "Expected hideProgressView to be called once.")
        #expect(router.exportedFiles_calledTimes == 1, "Expected exportedFiles to be called once.")
        #expect(router.exportedUrls == expectedURLs, "Expected exported URLs to be \(expectedURLs) but got \(router.exportedUrls).")
        #expect(analyticsUseCase.type == .download(.exportFile), "Expected analytics event to be sent.")
    }
    
    @MainActor
    private static func makeSUT(urls: [URL]) -> (ExportFileViewModel, MockExportFileViewRouter, MockExportFileUseCase, MockAnalyticsEventUseCase) {
        let router = MockExportFileViewRouter()
        let exportUseCase = MockExportFileUseCase(
            exportNodeResult: urls.first,
            exportNodesResult: urls,
            exportMessagesResult: urls,
            exportNodeFromMessageResult: urls.first
        )
        let analyticsUseCase = MockAnalyticsEventUseCase()
        let sut = ExportFileViewModel(
            router: router,
            analyticsEventUseCase: analyticsUseCase,
            exportFileUseCase: exportUseCase
        )
        
        return (sut, router, exportUseCase, analyticsUseCase)
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
            let (sut, router, exportUseCase, _) = makeSUT(urls: [URL(string: "mock://file1")!])
            
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
