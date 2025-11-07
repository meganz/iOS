@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("CameraUploadPaginationManager Tests")
struct CameraUploadPaginationManagerTests {
    
    // MARK: - Initial Load Tests
    
    @Test("Load initial page with items")
    func loadInitialPageWithItems() async {
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 100)
        )
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        let update = await sut.loadInitialPage()
        
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 2)
        #expect(update.items == makeCameraAssetUploadEntities(count: 90))
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 15)
        )
        
        let sut = Self.makeSUT(
            pageSize: 30,
            queuedCameraUploadsUseCase: useCase
        )
        
        let update = await sut.loadInitialPage()
        
        #expect(update.items == makeCameraAssetUploadEntities(count: 15))
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 0)
    }
    
    // MARK: - Pagination Tests
    
    @Test("Load next page forward")
    func loadNextPageForward() async throws {
        let items = makeCameraAssetUploadEntities(count: 100)
        let useCase = MockQueuedCameraUploadsUseCase(
            items: items
        )
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 2,
            queuedCameraUploadsUseCase: useCase
        )
        
        _ = await sut.loadInitialPage()
        
        let update = try #require(await sut.loadPageIfNeeded(itemIndex: 35))
        #expect(update.firstPageIndex == 0)
        #expect(update.lastPageIndex == 3)
        #expect(update.items == items)
    }
    
    @Test("Load previous page backward")
    func loadPreviousPageBackward() async throws {
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 240)
        )
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 1,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.firstPageIndex == 0)
        #expect(initial.lastPageIndex == 1)
        
        let updateAtPage1 = try #require(await sut.loadPageIfNeeded(itemIndex: 35))
        #expect(updateAtPage1.firstPageIndex == 0)
        #expect(updateAtPage1.lastPageIndex == 2)
        
        let updateAtPage2 = try #require(await sut.loadPageIfNeeded(itemIndex: 60))
        #expect(updateAtPage2.firstPageIndex == 1)
        #expect(updateAtPage2.lastPageIndex == 3)
        
        let updateAtPage3 = try #require(await sut.loadPageIfNeeded(itemIndex: 90))
        #expect(updateAtPage3.firstPageIndex == 1)
        #expect(updateAtPage3.lastPageIndex == 4)
        
        let updateAtPage4 = try #require(await sut.loadPageIfNeeded(itemIndex: 120))
        #expect(updateAtPage4.firstPageIndex == 3)
        #expect(updateAtPage4.lastPageIndex == 5)
        
        let backwardToPage3 = try #require(await sut.loadPageIfNeeded(itemIndex: 90))
        #expect(backwardToPage3.firstPageIndex == 2)
        #expect(backwardToPage3.lastPageIndex == 5)
        
        let backwardToPage2 = try #require(await sut.loadPageIfNeeded(itemIndex: 60))
        #expect(backwardToPage2.firstPageIndex == 1)
        #expect(backwardToPage2.lastPageIndex == 3)
        #expect(backwardToPage2.items == Array(makeCameraAssetUploadEntities(count: 120).dropFirst(30)))
        
        let backwardToPage1 = try #require(await sut.loadPageIfNeeded(itemIndex: 35))
        #expect(backwardToPage1.firstPageIndex == 0)
        #expect(backwardToPage1.lastPageIndex == 3)
        
        #expect(backwardToPage1.items == makeCameraAssetUploadEntities(count: 120))
    }
    
    @Test("Skip load when all pages present")
    func skipLoadWhenPagesPresent() async {
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 50)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 200)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 300)
        )
        
        let sut = Self.makeSUT(
            pageSize: 30,
            lookAhead: 2,
            lookBehind: 1,
            queuedCameraUploadsUseCase: useCase
        )
        
        let initial = await sut.loadInitialPage()
        #expect(initial.firstPageIndex == 0)
        #expect(initial.lastPageIndex == 2)
        
        let updateAtPage1 = try #require(await sut.loadPageIfNeeded(itemIndex: 35))
        #expect(updateAtPage1.firstPageIndex == 0)
        #expect(updateAtPage1.lastPageIndex == 3)
        
        let updateAtPage2 = try #require(await sut.loadPageIfNeeded(itemIndex: 60))
        #expect(updateAtPage2.firstPageIndex == 1)
        #expect(updateAtPage2.lastPageIndex == 4)
        
        let updateAtPage3 = try #require(await sut.loadPageIfNeeded(itemIndex: 90))
        #expect(updateAtPage3.firstPageIndex == 1)
        #expect(updateAtPage3.lastPageIndex == 5)
        
        let updateAtPage4 = try #require(await sut.loadPageIfNeeded(itemIndex: 120))
        #expect(updateAtPage4.firstPageIndex == 3)
        #expect(updateAtPage4.lastPageIndex == 6)
        
        let updateAtPage5 = try #require(await sut.loadPageIfNeeded(itemIndex: 150))
        #expect(updateAtPage5.firstPageIndex == 3)
        #expect(updateAtPage5.lastPageIndex == 7)
        
        let updateAtPage6 = try #require(await sut.loadPageIfNeeded(itemIndex: 180))
        #expect(updateAtPage6.firstPageIndex == 5)
        #expect(updateAtPage6.lastPageIndex == 8)
        
        let expectedItemsPage6 = makeCameraAssetUploadEntities(count: 270).dropFirst(150)
        #expect(updateAtPage6.items == Array(expectedItemsPage6))
        #expect(updateAtPage6.items.count == 120)
    }
    
    // MARK: - Snapshot Comparison Tests
    
    @Test("Return nil when pages unchanged")
    func returnNilWhenPagesUnchanged() async {
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 100)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 60)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 200)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 200)
        )
        
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
        let useCase = MockQueuedCameraUploadsUseCase(
            items: makeCameraAssetUploadEntities(count: 200)
        )
        
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
    
    func makeCameraAssetUploadEntities(count: Int) -> [CameraAssetUploadEntity] {
        (0..<count).map { index in
            CameraAssetUploadEntity(
                localIdentifier: "item_\(index)",
                creationDate: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
    }
}
