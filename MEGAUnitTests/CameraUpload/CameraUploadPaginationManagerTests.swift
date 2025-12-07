@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("CameraUploadPaginationManager Tests")
struct CameraUploadPaginationManagerTests {
    
    // MARK: - Initial Load Tests
    
    @Test("Load initial page with items")
    func loadInitialPageWithItems() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 100)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        let update = await sut.loadInitialPage()
        
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 2)
        let expectedUpdateItems = makeCameraAssetUploadEntities(count: 90)
        #expect(update.items == expectedUpdateItems)
    }
    
    @Test("Load initial page with no items")
    func loadInitialPageEmpty() async {
        let useCase = MockQueuedCameraUploadsUseCase()
        
        let sut = Self.makeSUT(
            pageSize: 30,
            queuedCameraUploadsUseCase: useCase
        )
        
        let update = await sut.loadInitialPage()
        
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 0)
        #expect(update.items.isEmpty)
    }
    
    @Test("Load initial page with fewer items than page size")
    func loadInitialPagePartial() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 15)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            queuedCameraUploadsUseCase: useCase
        )
        
        let update = await sut.loadInitialPage()
        
        #expect(update.items == expectedItems)
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 0)
    }
    
    // MARK: - Pagination Tests
    
    @Test("Load next page forward")
    func loadNextPageForward() async throws {
        let items = makeCameraAssetUploadEntities(count: 100)
        let useCase = MockQueuedCameraUploadsUseCase(items: items)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        try await assertPageLoadWithItems(
            sut: sut,
            itemIndex: 35,
            expectedFirst: 0,
            expectedLast: 3,
            expectedItems: items)
    }
    
    @Test("Load previous page backward")
    func loadPreviousPageBackward() async throws {
        let expectedItems = makeCameraAssetUploadEntities(count: 300)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 1,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.firstPageIndex == 0)
        #expect(initial.lastPageIndex == 1)
        
        _ = await sut.loadPageIfNeeded(itemIndex: 30)
        _ = await sut.loadPageIfNeeded(itemIndex: 60)
        _ = await sut.loadPageIfNeeded(itemIndex: 90)
        _ = await sut.loadPageIfNeeded(itemIndex: 120)
        _ = await sut.loadPageIfNeeded(itemIndex: 150)
        
        _ = await sut.loadPageIfNeeded(itemIndex: 120)
        _ = await sut.loadPageIfNeeded(itemIndex: 90)
        _ = await sut.loadPageIfNeeded(itemIndex: 60)
        try await assertPageLoad(sut: sut, itemIndex: 30, expectedFirst: 0, expectedLast: 3)
    }
    
    @Test("Skip load when all pages present")
    func skipLoadWhenPagesPresent() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 50)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        _ = await sut.loadPageIfNeeded(itemIndex: 15)
        let secondUpdate = await sut.loadPageIfNeeded(itemIndex: 15)
        
        #expect(secondUpdate == nil)
    }
    
    @Test("Return nil when user scrolled past loaded pages")
    func returnNilWhenScrolledPast() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 300)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        // With jumpThreshold = max(2,2) + 1 = 3, need to jump >3 pages from loaded range
        // Initial loads pages 0-2, so jumping to page 7+ (itemIndex 210+) should return nil
        let farUpdate = await sut.loadPageIfNeeded(itemIndex: 240)
        
        #expect(farUpdate == nil)
    }
    
    // MARK: - Page Eviction Tests
    
    @Test("Evict distant pages when scrolling far")
    func evictDistantPages() async throws {
        let expectedItems = makeCameraAssetUploadEntities(count: 300)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.firstPageIndex == 0)
        #expect(initial.lastPageIndex == 2)
        
        // With new buffer-based eviction (2x buffer = ±4 pages), pages are kept longer
        try await assertPageLoad(sut: sut, itemIndex: 35, expectedFirst: 0, expectedLast: 3)
        try await assertPageLoad(sut: sut, itemIndex: 60, expectedFirst: 0, expectedLast: 4) // Pages 0-1 still kept
        try await assertPageLoad(sut: sut, itemIndex: 90, expectedFirst: 0, expectedLast: 5) // Pages 0-2 still kept
        try await assertPageLoad(sut: sut, itemIndex: 120, expectedFirst: 0, expectedLast: 6) // Pages 0-3 still kept
        try await assertPageLoad(sut: sut, itemIndex: 150, expectedFirst: 1, expectedLast: 7) // Page 0 finally evicted
        
        // At this point, scrolling to 180 (page 6) with buffer=4 keeps pages 2-10
        let allExpectedItems = makeCameraAssetUploadEntities(count: 300)
        let expectedItemsPage6 = Array(allExpectedItems.dropFirst(60).prefix(210)) // Pages 2-8 (items 60-269)
        try await assertPageLoadWithItems(
            sut: sut,
            itemIndex: 180,
            expectedFirst: 2,
            expectedLast: 8,
            expectedItems: expectedItemsPage6)
        #expect(expectedItemsPage6.count == 210)
    }
    
    // MARK: - Snapshot Comparison Tests
    
    @Test("Return nil when pages unchanged")
    func returnNilWhenPagesUnchanged() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 100)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        _ = await sut.loadPageIfNeeded(itemIndex: 25)
        
        let unchangedUpdate = await sut.loadPageIfNeeded(itemIndex: 25)
        
        #expect(unchangedUpdate == nil)
    }
    
    // MARK: - Remove Item Tests
    
    @Test("Remove item from loaded pages")
    func removeItemFromPages() async throws {
        let expectedItems = makeCameraAssetUploadEntities(count: 60)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 10,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.items.count == 30)
        
        await sut.removeItemFromPages(localIdentifier: "item_5")
        
        let updated = try #require(await sut.loadPageIfNeeded(itemIndex: 10))
        #expect(updated.items.notContains { $0.localIdentifier == "item_5" })
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("Handle concurrent pagination requests")
    func concurrentPaginationRequests() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 200)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        async let update1 = sut.loadPageIfNeeded(itemIndex: 25)
        async let update2 = sut.loadPageIfNeeded(itemIndex: 55)
        async let update3 = sut.loadPageIfNeeded(itemIndex: 85)
        
        let results = await [update1, update2, update3]
        
        #expect(results.count == 3)
    }
    
    // MARK: - Look Ahead/Behind Tests
    
    @Test("Look ahead loads correct number of pages")
    func lookAheadLoading() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 200)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 3,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.items.count >= 30)
    }
    
    @Test("Look behind loads correct number of pages")
    func lookBehindLoading() async {
        let expectedItems = makeCameraAssetUploadEntities(count: 200)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 3,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        // First load forward to enable backward loading
        _ = await sut.loadPageIfNeeded(itemIndex: 90) // Load up to page 3
        
        // Now test backward loading
        let backwardUpdate = await sut.loadPageIfNeeded(itemIndex: 35)
        
        #expect(backwardUpdate != nil)
    }
    
    private static func makeSUT(
        pageSize: Int = 30,
        lookAhead: Int = 2,
        lookBehind: Int = 2,
        queuedCameraUploadsUseCase: some QueuedCameraUploadsUseCaseProtocol = MockQueuedCameraUploadsUseCase()
    ) -> CameraUploadPaginationManager {
        .init(
            pageSize: pageSize,
            lookAhead: lookAhead,
            lookBehind: lookBehind,
            queuedCameraUploadsUseCase: queuedCameraUploadsUseCase)
    }
    
    // MARK: - Helper Methods
    
    private  func makeCameraAssetUploadEntities(count: Int) -> [CameraAssetUploadEntity] {
        (0..<count).map { index in
            CameraAssetUploadEntity(
                localIdentifier: "item_\(index)",
                creationDate: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
    }
    
    private func assertPageLoad(
        sut: CameraUploadPaginationManager,
        itemIndex: Int,
        expectedFirst: Int,
        expectedLast: Int
    ) async throws {
        let update = try #require(await sut.loadPageIfNeeded(itemIndex: itemIndex))
        #expect(update.firstPageIndex == expectedFirst)
        #expect(update.lastPageIndex == expectedLast)
    }
    
    private func assertPageLoadWithItems(
        sut: CameraUploadPaginationManager,
        itemIndex: Int,
        expectedFirst: Int,
        expectedLast: Int,
        expectedItems: [CameraAssetUploadEntity]
    ) async throws {
        let update = try #require(await sut.loadPageIfNeeded(itemIndex: itemIndex))
        #expect(update.firstPageIndex == expectedFirst)
        #expect(update.lastPageIndex == expectedLast)
        #expect(update.items == expectedItems)
    }
    
    private func assertPageLoadWithItems(
        sut: CameraUploadPaginationManager,
        itemIndex: Int,
        expectedFirst: Int,
        expectedLast: Int,
        expectedPages: Int
    ) async throws {
        let update = try #require(await sut.loadPageIfNeeded(itemIndex: itemIndex))
        #expect(update.firstPageIndex == expectedFirst)
        #expect(update.lastPageIndex == expectedLast)
        let expectedItemCount = expectedPages * 30
        #expect(update.items.count == expectedItemCount)
    }
}
