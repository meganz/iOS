import CoreData
@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

struct OfflineFilesRepositoryTestSuite {
    private static let mockNodeHandle: HandleEntity = 123
    private static let testNodeName = "Test Node"
    private static let testOfflineURL = URL(string: "/mock/offline/path")
    private static let testLocalPath = "test/path"
    
    @Suite("OfflineFilesRepository offlineURL Tests")
    struct OfflineURLTests {
        @Test("When offlinePath exists, should return a valid URL")
        func whenOfflinePathExists_shouldReturnValidURL() throws {
            let (sut, _) = makeSUT(offlineURL: testOfflineURL)
            #expect(sut.offlineURL == testOfflineURL)
        }
        
        @Test("When offlinePath is nil, should return nil")
        func whenOfflinePathIsNil_shouldReturnNil() throws {
            let (sut, _) = makeSUT(offlineURL: nil)
            #expect(sut.offlineURL == nil)
        }
    }
    
    // @MainActor: the in-memory context is main queue, so the test body must stay on the main thread.
    @Suite("OfflineFilesRepository createOfflineFile Tests")
    @MainActor
    struct CreateOfflineFileTests {
        // The context must outlive the node it creates. A node whose context is gone crashes on access.
        private let context = makeInMemoryContext()

        @Test("With a valid node handle, should insert an offline node")
        func withValidNode_shouldInsertOfflineNode() throws {
            let mockNode = MockNode(handle: mockNodeHandle,
                                    name: testNodeName)
            let sdk = MockSdk(nodes: [mockNode])
            let (sut, mockStore) = makeSUT(sdk: sdk)
            
            sut.createOfflineFile(
                name: testLocalPath,
                for: mockNodeHandle
            )
            
            #expect(mockStore.insertOfflineNode_calledTimes == 1)
            #expect(mockStore.insertOfflineNode_lastPath == testLocalPath)
        }
        
        @Test("With an invalid node handle, should not insert an offline node")
        func withInvalidNode_shouldNotInsertOfflineNode() throws {
            let sdk = MockSdk(nodes: [])
            let (sut, mockStore) = makeSUT(sdk: sdk)
            
            sut.createOfflineFile(
                name: testLocalPath,
                for: mockNodeHandle
            )
            
            #expect(mockStore.insertOfflineNode_calledTimes == 0)
        }

        @Test("With the same node already saved at the same path, should not insert a duplicate")
        func withSameNodeAtSamePath_shouldNotInsertOfflineNode() throws {
            let base64Handle = "abc123"
            let mockNode = MockNode(handle: mockNodeHandle,
                                    nodeBase64Handle: base64Handle,
                                    name: testNodeName)
            let sdk = MockSdk(nodes: [mockNode])
            let store = MockMEGAStore(
                offlineNodesWithPath: [makeOfflineNode(base64Handle: base64Handle, localPath: testLocalPath, in: context)]
            )
            let (sut, mockStore) = makeSUT(sdk: sdk, store: store)

            sut.createOfflineFile(
                name: testLocalPath,
                for: mockNodeHandle
            )

            #expect(mockStore.insertOfflineNode_calledTimes == 0)
        }

        @Test("With a different node saved at the same path, should insert an offline node")
        func withDifferentNodeAtSamePath_shouldInsertOfflineNode() throws {
            let mockNode = MockNode(handle: mockNodeHandle,
                                    nodeBase64Handle: "abc123",
                                    name: testNodeName)
            let sdk = MockSdk(nodes: [mockNode])
            let store = MockMEGAStore(
                offlineNodesWithPath: [makeOfflineNode(base64Handle: "other456", localPath: testLocalPath, in: context)]
            )
            let (sut, mockStore) = makeSUT(sdk: sdk, store: store)

            sut.createOfflineFile(
                name: testLocalPath,
                for: mockNodeHandle
            )

            #expect(mockStore.insertOfflineNode_calledTimes == 1)
            #expect(mockStore.insertOfflineNode_lastPath == testLocalPath)
        }
    }

    @Suite("OfflineFilesRepository removeAllStoredOfflineNodes Tests")
    struct RemoveAllOfflineNodesTests {
        @Test("With a valid path, should call store")
        func withValidPath_shouldRemoveContentsAndCallStore() async throws {
            let mockNode = MockNode(
                handle: mockNodeHandle,
                name: testNodeName
            )
            let sdk = MockSdk(nodes: [mockNode])
            let (sut, mockStore) = makeSUT(
                sdk: sdk,
                fileManager: MockFileManager(contentsOfDirectory: ["test"]),
                offlineURL: testOfflineURL
            )
            
            sut.removeAllStoredOfflineNodes()
            
            #expect(mockStore.removeAllOfflineNodes_calledTimes == 1)
        }
    }
    
    @Suite("OfflineFilesRepository offlineSize Tests")
    struct OfflineSizeTests {
        @Test("When offlineURL is nil, should return 0")
        func whenOfflineURLIsNil_shouldReturnZero() throws {
            let (sut, _) = makeSUT(offlineURL: nil)
            
            #expect(sut.offlineSize() == 0)
        }
        
        @Test("When offlineURL is valid, should return calculated folder size")
        func whenOfflineURLIsValid_shouldReturnCalculatedSize() throws {
            let expectedSize: UInt64 = 1024
            let (sut, _) = makeSUT(folderSize: expectedSize)
            
            #expect(sut.offlineSize() == expectedSize)
        }
        
        @Test("When folder size calculator returns 0, should return 0")
        func whenFolderSizeIsZero_shouldReturnZero() throws {
            let expectedSize: UInt64 = 0
            
            let (sut, _) = makeSUT(folderSize: expectedSize)
            
            #expect(sut.offlineSize() == expectedSize)
        }
    }
    
    private static func makeOfflineNode(base64Handle: String, localPath: String, in context: NSManagedObjectContext) -> MOOfflineNode {
        OfflineFileEntity(
            base64Handle: base64Handle,
            localPath: localPath,
            parentBase64Handle: nil,
            fingerprint: nil,
            timestamp: nil
        ).toMOOfflineNode(in: context)
    }

    private static func makeInMemoryContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(
                ofType: NSInMemoryStoreType,
                configurationName: nil,
                at: nil,
                options: nil
            )
        } catch {
            fatalError("Error adding in-memory persistent store: \(error)")
        }

        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        return context
    }

    private static func makeSUT(
        sdk: MockSdk = MockSdk(),
        fileManager: FileManager = MockFileManager(),
        offlineURL: URL? = testOfflineURL,
        folderSize: UInt64 = 0,
        store: MockMEGAStore = MockMEGAStore()
    ) -> (OfflineFilesRepository, MockMEGAStore) {
        let sut = OfflineFilesRepository(
            store: store,
            offlineURL: offlineURL,
            sdk: sdk,
            folderSizeCalculator: MockFolderSizeCalculator(folderSize: folderSize)
        )
        return (sut, store)
    }
}
