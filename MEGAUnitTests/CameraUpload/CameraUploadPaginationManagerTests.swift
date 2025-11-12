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
        let expectedItems = makeCameraAssetUploadEntities(count: 240)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 1,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        await testInitialLoadForBackwardPagination(sut: sut)
        try await testForwardPaginationPages(sut: sut)
        try await testBackwardPaginationPages(sut: sut)
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
        let expectedItems = makeCameraAssetUploadEntities(count: 200)
        let useCase = MockQueuedCameraUploadsUseCase(items: expectedItems)
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        let farUpdate = await sut.loadPageIfNeeded(itemIndex: 150)
        
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
        
        try await assertPageLoad(sut: sut, itemIndex: 35, expectedFirst: 0, expectedLast: 3)
        try await assertPageLoad(sut: sut, itemIndex: 60, expectedFirst: 1, expectedLast: 4)
        try await assertPageLoad(sut: sut, itemIndex: 90, expectedFirst: 1, expectedLast: 5)
        try await assertPageLoad(sut: sut, itemIndex: 120, expectedFirst: 3, expectedLast: 6)
        try await assertPageLoad(sut: sut, itemIndex: 150, expectedFirst: 3, expectedLast: 7)
        
        let allExpectedItems = makeCameraAssetUploadEntities(count: 270)
        let expectedItemsPage6 = Array(allExpectedItems.dropFirst(150))
        try await assertPageLoadWithItems(
            sut: sut,
            itemIndex: 180,
            expectedFirst: 5,
            expectedLast: 8,
            expectedItems: expectedItemsPage6)
        #expect(expectedItemsPage6.count == 120)
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
        _ = await sut.loadPageIfNeeded(itemIndex: 60)
        
        let backwardUpdate = await sut.loadPageIfNeeded(itemIndex: 40)
        
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
    
    private func testForwardPaginationPages(sut: CameraUploadPaginationManager) async throws {
        try await assertPageLoad(sut: sut, itemIndex: 35, expectedFirst: 0, expectedLast: 2)
        try await assertPageLoad(sut: sut, itemIndex: 60, expectedFirst: 1, expectedLast: 3)
        try await assertPageLoad(sut: sut, itemIndex: 90, expectedFirst: 1, expectedLast: 4)
        try await assertPageLoad(sut: sut, itemIndex: 120, expectedFirst: 3, expectedLast: 5)
    }
    
    private func testBackwardPaginationPages(sut: CameraUploadPaginationManager) async throws {
        try await assertPageLoad(sut: sut, itemIndex: 90, expectedFirst: 2, expectedLast: 5)
        
        let expectedBackwardItems: [CameraAssetUploadEntity] = Array(makeCameraAssetUploadEntities(count: 120).dropFirst(30))
        try await assertPageLoadWithItems(sut: sut, itemIndex: 60, expectedFirst: 1, expectedLast: 3, expectedItems: expectedBackwardItems)
        
        let expectedPage1Items: [CameraAssetUploadEntity] = makeCameraAssetUploadEntities(count: 120)
        try await assertPageLoadWithItems(sut: sut, itemIndex: 35, expectedFirst: 0, expectedLast: 3, expectedItems: expectedPage1Items)
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
    
    private func testInitialLoadForBackwardPagination(sut: CameraUploadPaginationManager) async {
        let initial = await sut.loadInitialPage()
        #expect(initial.firstPageIndex == 0)
        #expect(initial.lastPageIndex == 1)
    }
}
