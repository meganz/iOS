import Combine
import CoreData
import MEGADomain
import MEGADomainMock
import MEGAFoundation
import MEGASwift
import MEGATest
import XCTest

@testable import MEGA

final class OfflineViewModelTests: XCTestCase {
    private let relativePath = "relative/path"
    private let directoryPath = "/mock/path/expected"
    private let filepath = "/mock/path/expected/logFile"
    private let logsDirectoryPath = "/mock/path/expected/logs"
    private let logsFileName = "MEGAiOS.docExt.log"
    private let anyError = NSError(domain: "OfflineTestsError", code: 1, userInfo: nil)
    
    var logsFilePath: String {
        logsDirectoryPath + "/" + logsFileName
    }
    
    // MARK: - Helpers
    
    private struct TestConfig {
        var offlineUseCase: MockOfflineUseCase = MockOfflineUseCase()
        var megaStore: MockMEGAStore = MockMEGAStore()
        var fileManager: MockFileManager = MockFileManager()
        var documentDirectoryPath: String?
        var urls: [URL]
        var expectedCommand: OfflineViewModel.Command?
        var deleteOfflineAppearancePreferenceCalled: Int = 0
        var removeCalled: Int = 0
    }
    
    @MainActor
    private func makeOfflineViewModelVMSut(
        offlineUseCase: some OfflineUseCaseProtocol = MockOfflineUseCase(),
        megaStore: MEGAStore = MockMEGAStore(),
        fileManager: MockFileManager = MockFileManager(),
        documentDirectoryPath: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> OfflineViewModel {
        
        let sut = OfflineViewModel(
            offlineUseCase: offlineUseCase,
            megaStore: megaStore,
            fileManager: fileManager,
            documentsDirectoryPath: documentDirectoryPath,
            throttler: MockThrottler()
        )
        trackForMemoryLeaks(on: sut, timeoutNanoseconds: 1_000_000_000)
        return sut
    }
    
    @MainActor
    private func executeRemoveOfflineItemsTest(
        config: TestConfig,
        function: String = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let sut = makeOfflineViewModelVMSut(
            offlineUseCase: config.offlineUseCase,
            megaStore: config.megaStore,
            fileManager: config.fileManager,
            documentDirectoryPath: config.documentDirectoryPath,
            file: file,
            line: line
        )
        let expectation = expectation(description: function)
        
        var receivedCommand: OfflineViewModel.Command?
        
        sut.invokeCommand = { command in
            receivedCommand = command
            expectation.fulfill()
        }
        
        sut.dispatch(.removeOfflineItems(config.urls))
        await fulfillment(of: [expectation], timeout: 1)
        
        XCTAssertEqual(config.megaStore.deleteOfflineAppearancePreference_calledTimes, config.deleteOfflineAppearancePreferenceCalled, file: file, line: line)
        XCTAssertEqual(config.megaStore.remove_calledTimes, config.removeCalled, file: file, line: line)
        XCTAssertEqual(receivedCommand, config.expectedCommand, file: file, line: line)
    }
    
    // MARK: - Tests
    
    @MainActor
    func testAction_onViewAppear_shouldReloadUIWhenNodeDownloadCompletionUpdatesAvaliable() async {
        // given
        let offlineUseCase = MockOfflineUseCase(
            nodeDownloadCompletionUpdates: [()].async.eraseToAnyAsyncSequence()
        )
        let sut = makeOfflineViewModelVMSut(offlineUseCase: offlineUseCase)
        
        let expectation = expectation(description: #function)
        var receivedCommand: OfflineViewModel.Command?
        
        sut.invokeCommand = {
            receivedCommand = $0
            expectation.fulfill()
        }
        
        // when
        sut.dispatch(.onViewAppear)
        
        await fulfillment(of: [expectation], timeout: 1)
        
        // then
        XCTAssertEqual(receivedCommand, .reloadUI)
    }

    @MainActor
    func testAction_onViewWillDisappear_shouldStopMonitoringNodeDownloadCompletionUpdates() async {
        // given
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let offlineUseCase = MockOfflineUseCase(nodeDownloadCompletionUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeOfflineViewModelVMSut(offlineUseCase: offlineUseCase)
        
        let expectation = expectation(description: #function)
        
        continuation.onTermination = { _ in
            expectation.fulfill()
        }
        
        // when
        sut.dispatch(.onViewAppear)
        sut.dispatch(.onViewWillDisappear)
        
        await fulfillment(of: [expectation], timeout: 1)
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
    
    @MainActor
    func testAction_removeOfflineItems_shouldCallDeleteOfflineAppearancePreferenceForDirectory() async {
        let config = TestConfig(
            offlineUseCase: {
                let useCase = MockOfflineUseCase()
                useCase.stubbedRelativePath = relativePath
                return useCase
            }(),
            urls: [URL(fileURLWithPath: directoryPath, isDirectory: true)],
            expectedCommand: .reloadUI,
            deleteOfflineAppearancePreferenceCalled: 1
        )
        
        await executeRemoveOfflineItemsTest(config: config)
    }
    
    @MainActor
    func testAction_removeOfflineItems_shouldCallRemoveForOfflineNode() async {
        let config = TestConfig(
            offlineUseCase: {
                let useCase = MockOfflineUseCase()
                useCase.stubbedRelativePath = relativePath
                return useCase
            }(),
            megaStore: MockMEGAStore(offlineNode: makeOfflineNode),
            urls: [URL(fileURLWithPath: filepath, isDirectory: false)],
            expectedCommand: .reloadUI,
            removeCalled: 1
        )
        
        await executeRemoveOfflineItemsTest(config: config)
    }
    
    @MainActor
    func testAction_removeOfflineItems_shouldHandleErrorsGracefully() async {
        let config = TestConfig(
            offlineUseCase: {
                let useCase = MockOfflineUseCase()
                useCase.stubbedError = anyError
                return useCase
            }(),
            urls: [URL(fileURLWithPath: filepath)],
            expectedCommand: .reloadUI,
            removeCalled: 0
        )
        
        await executeRemoveOfflineItemsTest(config: config)
    }
    
    @MainActor
    func testRemoveLogFromSharedSandbox_shouldSuccessfullyRemoveLog() async {
        let mockFileManager = MockFileManager(tempURL: URL(string: logsFilePath)!, containerURL: URL(string: directoryPath)!)
        let config = TestConfig(
            offlineUseCase: {
                let useCase = MockOfflineUseCase()
                useCase.stubbedRelativePath = relativePath
                return useCase
            }(),
            megaStore: MockMEGAStore(offlineNode: makeOfflineNode),
            fileManager: mockFileManager,
            documentDirectoryPath: directoryPath,
            urls: [URL(fileURLWithPath: directoryPath + "/" + logsFileName, isDirectory: false)],
            expectedCommand: .reloadUI,
            removeCalled: 1
        )
        
        await executeRemoveOfflineItemsTest(config: config)
        
        XCTAssertEqual(mockFileManager.lastRemovedPath, logsFilePath, "Expected to remove the log file successfully")
    }
    
    @MainActor
    func testRemoveLogFromSharedSandbox_shouldHandleErrorGracefully() async {
        let mockFileManager = MockFileManager(
            containerURL: URL(string: directoryPath)!,
            errorToThrow: anyError
        )
        let config = TestConfig(
            offlineUseCase: {
                let useCase = MockOfflineUseCase()
                useCase.stubbedRelativePath = relativePath
                return useCase
            }(),
            megaStore: MockMEGAStore(offlineNode: makeOfflineNode),
            fileManager: mockFileManager,
            documentDirectoryPath: directoryPath,
            urls: [URL(fileURLWithPath: directoryPath + "/" + logsFileName, isDirectory: false)],
            expectedCommand: .reloadUI,
            removeCalled: 1
        )
        
        await executeRemoveOfflineItemsTest(config: config)
        
        XCTAssertEqual(mockFileManager.lastRemovedPath, logsFilePath, "Expected to attempt removing the log file even with error")
    }
    
    private var makeOfflineNode: MOOfflineNode {
        let testStack = CoreDataTestStack()
        let context = testStack.managedObjectContext
        
        let offlineFileNode = OfflineFileEntity(
            base64Handle: "testHandle",
            localPath: "/test/path",
            parentBase64Handle: "parentHandle",
            fingerprint: "testFingerprint",
            timestamp: Date()
        )
        
        return offlineFileNode.toMOOfflineNode(in: context)
    }
}

// MARK: - Core Data Test Stack
private class CoreDataTestStack {
    lazy var managedObjectContext: NSManagedObjectContext = {
        createInMemoryManagedObjectContext()
    }()
    
    private func createInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            fatalError("Error adding in-memory persistent store: \(error)")
        }
        
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        return context
    }
}

private class MockThrottler: Throttleable {
    func start(action: @escaping () -> Void) {
        action()
    }
}
