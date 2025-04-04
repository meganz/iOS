@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class OfflineFileFetcherRepositoryTests: XCTestCase {
    
    let fileEntity = OfflineFileEntity(
        base64Handle: "123",
        localPath: "/path/to/file1",
        parentBase64Handle: nil,
        fingerprint: nil,
        timestamp: nil
    )
    
    let videoEntity = OfflineFileEntity(
        base64Handle: "456",
        localPath: "/path/to/video1",
        parentBase64Handle: "123",
        fingerprint: "fingerprint1",
        timestamp: Date()
    )
    
    private var testStack: CoreDataTestStack!
    
    override func setUp() {
        super.setUp()
        testStack = CoreDataTestStack()
    }
    
    override func tearDown() {
        testStack = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testFetchOfflineFiles_ShouldReturnMappedEntities() {
        let mockStore = makeMockStore(fetchOfflineNodes: [fileEntity, videoEntity])
        let sut = OfflineFileFetcherRepository(store: mockStore)
        
        let result = sut.offlineFiles()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].base64Handle, fileEntity.base64Handle)
        XCTAssertEqual(result[1].base64Handle, videoEntity.base64Handle)
    }
    
    func testFetchOfflineFiles_WhenNoNodesExist_ShouldReturnEmptyList() {
        let mockStore = makeMockStore(fetchOfflineNodes: [])
        let sut = OfflineFileFetcherRepository(store: mockStore)
        
        let result = sut.offlineFiles()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testFetchOfflineFile_WithValidHandle_ShouldReturnEntity() {
        let mockStore = makeMockStore(fetchOfflineNode: fileEntity)
        let sut = OfflineFileFetcherRepository(store: mockStore)
        
        let result = sut.offlineFile(for: fileEntity.base64Handle)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.base64Handle, fileEntity.base64Handle)
    }
    
    func testFetchOfflineFile_WithInvalidHandle_ShouldReturnNil() {
        let mockStore = makeMockStore(fetchOfflineNode: nil)
        let sut = OfflineFileFetcherRepository(store: mockStore)
        
        let result = sut.offlineFile(for: "invalidHandle")
        
        XCTAssertNil(result)
    }
    
    // MARK: - Helpers
    
    private func makeMockStore(
        fetchOfflineNodes: [OfflineFileEntity] = [],
        fetchOfflineNode: OfflineFileEntity? = nil
    ) -> MockMEGAStore {
        let nodes = fetchOfflineNodes.map { $0.toMOOfflineNode(in: testStack.context) }
        let singleNode = fetchOfflineNode?.toMOOfflineNode(in: testStack.context)
        
        return MockMEGAStore(
            fetchOfflineNodes: nodes,
            offlineNode: singleNode
        )
    }
}

// MARK: - Core Data Test Stack

private class CoreDataTestStack {
    let context: NSManagedObjectContext = createInMemoryManagedObjectContext()
    
    private static func createInMemoryManagedObjectContext() -> NSManagedObjectContext {
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
}
