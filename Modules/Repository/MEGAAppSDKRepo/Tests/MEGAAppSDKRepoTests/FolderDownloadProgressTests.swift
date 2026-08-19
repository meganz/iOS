@testable import MEGAAppSDKRepo
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FolderDownloadProgress counts a folder download in files")
struct FolderDownloadProgressTests {
    private static let folderTag = 7

    private static func makeSUT() -> FolderDownloadProgress {
        let sut = FolderDownloadProgress()
        sut.setFolderTransferTag(folderTag)
        return sut
    }

    private static func update(stage: TransferStageEntity, fileCount: UInt) -> FolderTransferUpdateEntity {
        FolderTransferUpdateEntity(
            transfer: TransferEntity(tag: folderTag, isFolderTransfer: true, stage: stage),
            stage: stage,
            folderCount: 1,
            createdFolderCount: 0,
            fileCount: fileCount
        )
    }

    private static func finishedFile(folderTransferTag: Int) -> TransferEntity {
        TransferEntity(isFolderTransfer: false, folderTransferTag: folderTransferTag)
    }

    @Test("the scanning stage never supplies a total, however far it climbed")
    func scanningStage_isNotATotal() {
        let sut = Self.makeSUT()

        // The scan walks the remote tree with the count at 0, then collision checks the files it found,
        // growing it towards the total. Stopping here leaves a number that is not one.
        sut.noteFolderUpdate(Self.update(stage: .scan, fileCount: 0))
        sut.noteFolderUpdate(Self.update(stage: .scan, fileCount: 18))
        sut.noteFolderUpdate(Self.update(stage: .scan, fileCount: 34))

        #expect(sut.result(isSuccess: false).fileCount == 0, "A partial scan says nothing about the size of the tree.")
    }

    @Test("the tree building stage supplies the total the finished scan arrived at")
    func treeBuildingStage_suppliesTheTotal() {
        let sut = Self.makeSUT()

        sut.noteFolderUpdate(Self.update(stage: .scan, fileCount: 34))
        sut.noteFolderUpdate(Self.update(stage: .createTree, fileCount: 120))

        #expect(sut.result(isSuccess: false).fileCount == 120)
    }

    @Test("the transferring stage wins, since it counts what will actually be attempted")
    func transferringStage_winsOverTheTree() {
        let sut = Self.makeSUT()

        sut.noteFolderUpdate(Self.update(stage: .createTree, fileCount: 120))
        sut.noteFolderUpdate(Self.update(stage: .transferringFiles, fileCount: 118))

        #expect(sut.result(isSuccess: true).fileCount == 118)
    }

    @Test("only the files under this folder are counted")
    func finishedFiles_areCountedByFolderTag() {
        let sut = Self.makeSUT()
        sut.noteFolderUpdate(Self.update(stage: .createTree, fileCount: 3))

        sut.record(Self.finishedFile(folderTransferTag: Self.folderTag))
        sut.record(Self.finishedFile(folderTransferTag: Self.folderTag))
        // Another folder download running at the same time, and a standalone file download.
        sut.record(Self.finishedFile(folderTransferTag: Self.folderTag + 1))
        sut.record(Self.finishedFile(folderTransferTag: 0))

        let result = sut.result(isSuccess: false)
        #expect(result.downloadedFileCount == 2)
        #expect(result.fileCount == 3)
    }

    /// The folder transfer itself comes down the same stream and must not count as one of its own files.
    @Test("the folder transfer is not counted as a file of itself")
    func folderTransfer_isNotCounted() {
        let sut = Self.makeSUT()

        sut.record(TransferEntity(isFolderTransfer: true, folderTransferTag: Self.folderTag))

        #expect(sut.result(isSuccess: false).downloadedFileCount == 0)
    }

    @Test("sub transfers that landed before the folder's own tag was known are still counted")
    func subTransfers_arriveBeforeTheTag() {
        let sut = FolderDownloadProgress()

        sut.record(Self.finishedFile(folderTransferTag: Self.folderTag))
        sut.setFolderTransferTag(Self.folderTag)

        #expect(sut.result(isSuccess: true).downloadedFileCount == 1)
    }
}
