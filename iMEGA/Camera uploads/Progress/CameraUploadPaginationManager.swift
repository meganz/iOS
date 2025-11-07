import MEGADomain

struct PaginationUpdate {
    let firstPageIndex: Int
    let lastPageIndex: Int
    let items: [CameraAssetUploadEntity]
}

protocol CameraUploadPaginationManagerProtocol: Actor {
    nonisolated var pageSize: Int { get }
    func loadInitialPage() async -> PaginationUpdate
    func loadPageIfNeeded(itemIndex: Int) async -> PaginationUpdate?
    func removeItemFromPages(localIdentifier: CameraUploadLocalIdentifierEntity)
    func reset()
    func cancelAll()
}

actor CameraUploadPaginationManager: CameraUploadPaginationManagerProtocol {
    struct Cursor: Equatable {
        let first: QueuedCameraUploadCursorEntity
        let last: QueuedCameraUploadCursorEntity
    }
    
    struct Page {
        let index: Int
        var items: [CameraAssetUploadEntity]
        var cursor: Cursor
        
        var isEmpty: Bool {
            items.isEmpty
        }
    }
    
    private struct PageSnapshot: Equatable {
        let pageIndices: [Int]
        let firstPageCursor: Cursor?
        let lastPageCursor: Cursor?
        
        init(pages: [Page]) {
            self.pageIndices = pages.map(\.index).sorted()
            self.firstPageCursor = pages.sorted { $0.index < $1.index }.first?.cursor
            self.lastPageCursor = pages.sorted { $0.index < $1.index }.last?.cursor
        }
    }
    
    enum FetchDirection {
        case forward
        case backward
    }
    
    private let lookAhead: Int
    private let lookBehind: Int
    private let queuedCameraUploadsUseCase: any QueuedCameraUploadsUseCaseProtocol
    
    private var pages: [Page] = []
    private var lastEvictionPageIndex: Int?
    
    private var pageTasks: [Int: Task<Void, Never>] = [:]
    private var hasInitialLoad = false
    private var canLoadForward = true
    private var canLoadBackward = true
    
    private var currentPageIndex: Int = 0
    
    let pageSize: Int
    
    init(pageSize: Int = 30,
         lookAhead: Int = 2,
         lookBehind: Int = 2,
         queuedCameraUploadsUseCase: some QueuedCameraUploadsUseCaseProtocol
    ) {
        self.pageSize = pageSize
        self.lookAhead = lookAhead
        self.lookBehind = lookBehind
        self.queuedCameraUploadsUseCase = queuedCameraUploadsUseCase
    }
    
    func fetchRecords(cursor: QueuedCameraUploadCursorEntity?, limit: Int, direction: FetchDirection) async throws -> [CameraAssetUploadEntity] {
        try await queuedCameraUploadsUseCase.queuedCameraUploads(
            startingFrom: cursor,
            isForward: direction == .forward,
            limit: limit)
    }
}

// MARK: - Paging & Loading
extension CameraUploadPaginationManager {
    
    func loadInitialPage() async -> PaginationUpdate {
        hasInitialLoad = true
        canLoadForward = true
        canLoadBackward = false
        
        do {
            let items = try await fetchRecords(cursor: nil, limit: pageSize, direction: .forward)
            
            guard !items.isEmpty,
                  let cursor = items.cursor else {
                return PaginationUpdate(firstPageIndex: 0, lastPageIndex: 0, items: [])
            }
            
            let page = Page(index: 0, items: items, cursor: cursor)
            pages = [page]
            
            if items.count < pageSize {
                canLoadForward = false
            }
            
            await triggerLookAheadLoading(currentPageIndex: 0)
            
            return buildPaginationUpdate()
        } catch {
            MEGALogError("[\(type(of: self))] Failed to fetch records for initial load: \(error)")
            return PaginationUpdate(firstPageIndex: 0, lastPageIndex: 0, items: [])
        }
    }
    
    func loadPageIfNeeded(itemIndex: Int) async -> PaginationUpdate? {
        guard hasInitialLoad else {
            return await loadInitialPage()
        }
        
        let requestedPageIndex = itemIndex / pageSize
        let snapshotBefore = PageSnapshot(pages: pages)
        
        if !canLoadBackward && requestedPageIndex > 0 {
            canLoadBackward = true
        }
        
        let minPageToKeep = requestedPageIndex - lookBehind
        let maxPageToKeep = requestedPageIndex + lookAhead
        
        let shouldEvict = if let lastEvictionPageIndex {
            abs(requestedPageIndex - lastEvictionPageIndex) >= 2
        } else {
            true
        }
        
        let needsEviction = shouldEvict && pages.contains { $0.index < minPageToKeep || $0.index > maxPageToKeep }
        let needsLookAhead = canLoadForward && !hasAllPages(in: (requestedPageIndex + 1)...maxPageToKeep)
        let needsLookBehind = canLoadBackward && requestedPageIndex > 0 && lookBehind > 0 && !hasAllPages(in: max(0, minPageToKeep)...(requestedPageIndex - 1))
        
        guard needsEviction || needsLookAhead || needsLookBehind || !pageTasks.isEmpty else {
            MEGALogDebug("[\(type(of: self))] Skipping load, all pages present")
            return nil
        }
        
        await cancelTasksOutsideRange(minPageToKeep...maxPageToKeep)
        
        if needsEviction {
            await evictDistantPages(currentPageIndex: requestedPageIndex)
            lastEvictionPageIndex = requestedPageIndex
        }
        
        await triggerLookAheadLoading(currentPageIndex: requestedPageIndex)
        await triggerLookBehindLoading(currentPageIndex: requestedPageIndex)
        
        currentPageIndex = requestedPageIndex
        
        let pageRange = pages.map { $0.index }
        let minLoadedPage = pageRange.min() ?? 0
        let maxLoadedPage = pageRange.max() ?? 0
        
        let jumpThreshold = max(lookAhead, lookBehind) + 1
        guard !(requestedPageIndex > maxLoadedPage + jumpThreshold || requestedPageIndex < minLoadedPage - jumpThreshold) else {
            MEGALogDebug("[\(type(of: self))] User scrolled past loaded pages (viewing \(requestedPageIndex), loaded \(minLoadedPage)-\(maxLoadedPage))")
            return nil
        }
        
        let snapshotAfter = PageSnapshot(pages: pages)
        
        guard snapshotAfter != snapshotBefore else {
            return nil
        }
        
        return buildPaginationUpdate()
    }
    
    private func hasAllPages(in range: ClosedRange<Int>) -> Bool {
        for pageIndex in range where !pageExists(at: pageIndex) && pageTasks[pageIndex] == nil {
            return false
        }
        return true
    }
    
    private func cancelTasksOutsideRange(_ range: ClosedRange<Int>) async {
        for (pageIndex, task) in pageTasks where !range.contains(pageIndex) {
            task.cancel()
            pageTasks.removeValue(forKey: pageIndex)
        }
    }
    
    private func triggerLookAheadLoading(currentPageIndex: Int) async {
        guard canLoadForward else { return }
        let startIndex = currentPageIndex + 1
        let endIndex = currentPageIndex + lookAhead
        
        await triggerPageLoading(pageIndex: startIndex, direction: .forward, maxPageIndex: endIndex)
    }
    
    private func triggerLookBehindLoading(currentPageIndex: Int) async {
        guard canLoadBackward, currentPageIndex > 0, lookBehind > 0 else { return }
        let startIndex = currentPageIndex - 1
        let endIndex = max(0, currentPageIndex - lookBehind)
        
        await triggerPageLoading(pageIndex: startIndex, direction: .backward, maxPageIndex: endIndex)
    }
    
    private func triggerPageLoading(
        pageIndex: Int,
        direction: FetchDirection,
        maxPageIndex: Int
    ) async {
        var currentIndex = pageIndex
        
        while isWithinBounds(currentIndex, maxPageIndex: maxPageIndex, direction: direction) {
            guard !(pageExists(at: currentIndex) || pageTasks[currentIndex] != nil) else {
                currentIndex = nextIndex(from: currentIndex, direction: direction)
                continue
            }
            
            let cursor: QueuedCameraUploadCursorEntity? = switch direction {
            case .forward:
                forwardCursor(for: currentIndex)
            case .backward:
                backwardCursor(for: currentIndex)
            }
            
            guard let cursor else { break }
            
            let task = Task {
                await loadPage(pageIndex: currentIndex, cursor: cursor, direction: direction)
            }
            pageTasks[currentIndex] = task
            await task.value
            
            currentIndex = nextIndex(from: currentIndex, direction: direction)
        }
    }
    
    private func isWithinBounds(_ pageIndex: Int, maxPageIndex: Int, direction: FetchDirection) -> Bool {
        switch direction {
        case .forward:
            pageIndex <= maxPageIndex
        case .backward:
            pageIndex >= maxPageIndex
        }
    }
    
    private func nextIndex(from pageIndex: Int, direction: FetchDirection) -> Int {
        switch direction {
        case .forward:
            pageIndex + 1
        case .backward:
            pageIndex - 1
        }
    }
    
    private func loadPage(pageIndex: Int, cursor: QueuedCameraUploadCursorEntity?, direction: FetchDirection) async {
        defer { pageTasks.removeValue(forKey: pageIndex) }
        
        MEGALogDebug("[\(type(of: self))] Loading page \(pageIndex) (\(direction == .forward ? "forward" : "backward"))")
        
        do {
            var items = try await fetchRecords(cursor: cursor, limit: pageSize, direction: direction)
            
            guard !Task.isCancelled else {
                MEGALogDebug("[\(type(of: self))] Page \(pageIndex) cancelled")
                return
            }
            
            guard !items.isEmpty else {
                MEGALogDebug("[\(type(of: self))] Page \(pageIndex) empty, disabling \(direction == .forward ? "forward" : "backward") load")
                disableLoad(for: direction)
                return
            }
            
            if direction == .backward {
                items.reverse()
            }
            
            guard let cursor = items.cursor else {
                return
            }
            
            let page = Page(index: pageIndex, items: items, cursor: cursor)
            insertPage(page)
            
            guard items.count < pageSize else { return }
            disableLoad(for: direction)
        } catch {
            MEGALogError("[\(type(of: self))] Failed to load page \(pageIndex): \(error)")
        }
    }
    
    private func disableLoad(for direction: FetchDirection) {
        switch direction {
        case .forward:
            canLoadForward = false
        case .backward:
            canLoadBackward = false
        }
    }
    
    private func pageExists(at index: Int) -> Bool {
        pages.contains { $0.index == index }
    }
    
    private func forwardCursor(for pageIndex: Int) -> QueuedCameraUploadCursorEntity? {
        let previousPageIndex = pageIndex - 1
        guard let previousPage = pages.first(where: { $0.index == previousPageIndex }) else {
            return nil
        }
        return previousPage.cursor.last
    }
    
    private func backwardCursor(for pageIndex: Int) -> QueuedCameraUploadCursorEntity? {
        let nextPageIndex = pageIndex + 1
        guard let nextPage = pages.first(where: { $0.index == nextPageIndex }) else {
            return nil
        }
        return nextPage.cursor.first
    }
    
    private func insertPage(_ page: Page) {
        pages.removeAll { $0.index == page.index }
        
        guard let insertIndex = pages.firstIndex(where: { $0.index > page.index }) else {
            pages.append(page)
            return
        }
        pages.insert(page, at: insertIndex)
    }
}

// MARK: - Page Eviction
extension CameraUploadPaginationManager {
    
    private func evictDistantPages(currentPageIndex: Int) async {
        let minPageToKeep = currentPageIndex - lookBehind
        let maxPageToKeep = currentPageIndex + lookAhead
        
        for (pageIndex, task) in pageTasks where pageIndex < minPageToKeep || pageIndex > maxPageToKeep {
            task.cancel()
            pageTasks.removeValue(forKey: pageIndex)
        }
        
        pages.removeAll { page in
            let shouldEvict = page.index < minPageToKeep || page.index > maxPageToKeep
            if shouldEvict {
                MEGALogDebug("[\(type(of: self))] Evicting page data with index: \(page.index)")
            }
            return shouldEvict
        }
    }
}

// MARK: - Pagination Updates
extension CameraUploadPaginationManager {
    
    private func buildPaginationUpdate() -> PaginationUpdate {
        let sortedPages = pages.sorted { $0.index < $1.index }
        let allItems = sortedPages.flatMap { $0.items }
        
        let firstPageIndex = sortedPages.first?.index ?? 0
        let lastPageIndex = sortedPages.last?.index ?? 0
        
        return PaginationUpdate(
            firstPageIndex: firstPageIndex,
            lastPageIndex: lastPageIndex,
            items: allItems
        )
    }
    
}

// MARK: - Remove Item
extension CameraUploadPaginationManager {
    
    /// Removes item from loaded pages without triggering a pagination update
    /// This is used when items move to in-progress and we just need to remove them locally
    func removeItemFromPages(localIdentifier: CameraUploadLocalIdentifierEntity) {
        pages = pages.compactMap { page -> Page? in
            var updatedPage = page
            updatedPage.items.removeAll { $0.localIdentifier == localIdentifier }
            
            guard !updatedPage.items.isEmpty else { return nil }
            
            if let cursor = updatedPage.items.cursor {
                updatedPage.cursor = cursor
            }
            
            return updatedPage
        }
    }
    
    func reset() {
        cancelAll()
        pages.removeAll()
        lastEvictionPageIndex = nil
        currentPageIndex = 0
        hasInitialLoad = false
        canLoadForward = true
        canLoadBackward = true
    }
    
    func cancelAll() {
        pageTasks.values.forEach { $0.cancel() }
        pageTasks.removeAll()
    }
}

private extension [CameraAssetUploadEntity] {
    var cursor: CameraUploadPaginationManager.Cursor? {
        guard let firstItem = first,
              let lastItem = last else { return nil }
        
        return .init(
            first: .init(
                localIdentifier: firstItem.localIdentifier,
                creationDate: firstItem.creationDate),
            last: .init(
                localIdentifier: lastItem.localIdentifier,
                creationDate: lastItem.creationDate)
        )
    }
}

extension QueuedCameraUploadCursorEntity: @retroactive CustomDebugStringConvertible {
    public var debugDescription: String {
        "QueuedCameraUploadCursorEntity(localIdentifier: \"\(localIdentifier)\", creationDate: \(creationDate))"
    }
}
