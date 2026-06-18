import Foundation
import MEGADomain
import MEGADomainMock
import Search
import Testing
@testable import Transfer

@Suite("TransferSearchResultsProviderTests")
@MainActor
struct TransferSearchResultsProviderTests {

    // MARK: - Active

    @Test
    func snapshot_active_excludesFolderUploads() async {
        let folderUpload = TransferEntity(type: .upload, tag: 1, isFolderTransfer: true, state: .active)
        let fileUpload = TransferEntity(type: .upload, tag: 2, state: .active)
        let sut = makeSUT(filter: .active, transfers: [folderUpload, fileUpload])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: fileUpload)])
    }

    @Test
    func snapshot_active_excludesStreamingTransfers() async {
        let streaming = TransferEntity(type: .upload, tag: 1, isStreamingTransfer: true, state: .active)
        let fileUpload = TransferEntity(type: .upload, tag: 2, state: .active)
        let sut = makeSUT(filter: .active, transfers: [streaming, fileUpload])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: fileUpload)])
    }

    @Test
    func snapshot_active_includesPlainUpload() async {
        let fileUpload = TransferEntity(type: .upload, tag: 1, state: .active)
        let sut = makeSUT(filter: .active, transfers: [fileUpload])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: fileUpload)])
    }

    // MARK: - Completed

    @Test
    func snapshot_completed_excludesFolderTransfers() async {
        let folder = TransferEntity(type: .upload, tag: 1, isFolderTransfer: true, state: .complete)
        let file = TransferEntity(type: .upload, tag: 2, state: .complete)
        let sut = makeSUT(filter: .completed, completedTransfers: [folder, file])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: file)])
    }

    @Test
    func snapshot_completed_usesRecordedCompletionDateInRowState() async {
        let file = TransferEntity(
            type: .download,
            totalBytes: 2048,
            tag: 1,
            updateTime: Date(timeIntervalSince1970: 0),
            state: .complete
        )
        let registry = TransferRegistry()
        let sut = makeSUT(
            filter: .completed,
            completedTransfers: [file],
            registry: registry,
            finishDateProvider: MockTransferFinishDateProvider(
                datesByTag: [1: Date(timeIntervalSince1970: 1_723_316_940)]
            )
        )

        _ = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        let state = registry.rowViewModel(for: TransferEntityMapper.resultId(for: file))?.state
        #expect(state?.subtitle.contains(" · ") == true)
    }

    @Test
    func snapshot_completed_withoutRecordedDate_omitsDateSeparator() async {
        let file = TransferEntity(type: .download, totalBytes: 2048, tag: 1, state: .complete)
        let registry = TransferRegistry()
        let sut = makeSUT(filter: .completed, completedTransfers: [file], registry: registry)

        _ = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        let state = registry.rowViewModel(for: TransferEntityMapper.resultId(for: file))?.state
        #expect(state?.subtitle.contains(" · ") == false)
    }

    // MARK: - Failed

    @Test
    func snapshot_failed_excludesFolderTransfers() async {
        let folder = TransferEntity(type: .upload, tag: 1, isFolderTransfer: true, state: .failed)
        let file = TransferEntity(type: .upload, tag: 2, state: .failed)
        let sut = makeSUT(filter: .failed, completedTransfers: [folder, file])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: file)])
    }

    @Test
    func snapshot_failed_includesFailedAndCancelled_excludesComplete() async {
        let failed = TransferEntity(type: .download, tag: 1, state: .failed)
        let cancelled = TransferEntity(type: .upload, tag: 2, state: .cancelled)
        let complete = TransferEntity(type: .upload, tag: 3, state: .complete)
        let sut = makeSUT(filter: .failed, completedTransfers: [failed, cancelled, complete])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [
            TransferEntityMapper.resultId(for: failed),
            TransferEntityMapper.resultId(for: cancelled)
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        filter: TransferSearchResultsProvider.Filter,
        transfers: [TransferEntity] = [],
        completedTransfers: [TransferEntity] = [],
        registry: TransferRegistry? = nil,
        locationResolver: MockTransferLocationResolver = MockTransferLocationResolver(),
        finishDateProvider: MockTransferFinishDateProvider = MockTransferFinishDateProvider()
    ) -> TransferSearchResultsProvider {
        TransferSearchResultsProvider(
            filter: filter,
            inventoryUseCase: MockTransferInventoryUseCase(
                transfers: transfers,
                completedTransfers: completedTransfers
            ),
            counterUseCase: MockTransferCounterUseCase(),
            registry: registry ?? TransferRegistry(),
            locationResolver: locationResolver,
            finishDateProvider: finishDateProvider,
            clearTransfersUseCase: MockClearTransfersUseCase()
        )
    }
}

private struct MockTransferLocationResolver: TransferLocationResolving {
    let location: String?

    init(location: String? = nil) {
        self.location = location
    }

    func location(for entity: TransferEntity) async -> String? {
        location
    }
}

private struct MockTransferFinishDateProvider: TransferFinishDateProviding {
    let datesByTag: [Int: Date]

    init(datesByTag: [Int: Date] = [:]) {
        self.datesByTag = datesByTag
    }

    func finishDate(forTag tag: Int) -> Date? {
        datesByTag[tag]
    }

    func recordIfAbsent(tag: Int, date: Date) -> Date {
        datesByTag[tag] ?? date
    }

    func removeDates(forTags tags: Set<Int>) {}
}
