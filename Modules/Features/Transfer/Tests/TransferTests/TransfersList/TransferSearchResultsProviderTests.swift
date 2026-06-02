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

    // MARK: - Failed

    @Test
    func snapshot_failed_excludesFolderTransfers() async {
        let folder = TransferEntity(type: .upload, tag: 1, isFolderTransfer: true, state: .failed)
        let file = TransferEntity(type: .upload, tag: 2, state: .failed)
        let sut = makeSUT(filter: .failed, completedTransfers: [folder, file])

        let results = await sut.search(queryRequest: .initial, lastItemIndex: nil)

        #expect(results?.results.map(\.id) == [TransferEntityMapper.resultId(for: file)])
    }

    // MARK: - Helpers

    private func makeSUT(
        filter: TransferSearchResultsProvider.Filter,
        transfers: [TransferEntity] = [],
        completedTransfers: [TransferEntity] = []
    ) -> TransferSearchResultsProvider {
        TransferSearchResultsProvider(
            filter: filter,
            inventoryUseCase: MockTransferInventoryUseCase(
                transfers: transfers,
                completedTransfers: completedTransfers
            ),
            counterUseCase: MockTransferCounterUseCase(),
            registry: TransferRegistry(),
            locationResolver: MockTransferLocationResolver()
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
