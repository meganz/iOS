import Foundation
@testable import MEGA
import MEGADomain
import Testing

/// Covers the snapshot a `CancellableTransfer` is handed to the domain layer as.
///
/// Which fields matter is decided by the transfer's type, and the use case that receives it reads
/// only the ones its type has a use for; what is asserted here is that each of them arrives.
@Suite("Cancellable transfer domain mapping")
struct CancellableTransferDomainMappingTests {

    // MARK: - Upload

    @Test("An upload carries its local file, parent and resolved options")
    func upload() {
        let transfer = CancellableTransfer(
            parentHandle: 7,
            localFileURL: URL(fileURLWithPath: "/tmp/file.txt"),
            isFile: true,
            type: .upload,
            uploadOptions: UploadOptionsEntity(fileName: "original.txt", appData: "appData")
        )

        let entity = transfer.cancellableTransferEntity

        #expect(entity.type == .upload)
        #expect(entity.localFileURL == URL(fileURLWithPath: "/tmp/file.txt"))
        #expect(entity.parentHandle == 7)
        #expect(entity.isFile)
        #expect(entity.uploadOptions?.fileName == "original.txt")
        #expect(entity.uploadOptions?.appData == "appData")
    }

    /// The name is set when a collision is resolved with "Rename", which is why the snapshot is
    /// taken at the point the transfer is started rather than when it was built.
    @Test("An upload renamed after a collision carries the new name")
    func uploadRenamedAfterCollision() {
        let transfer = CancellableTransfer(
            parentHandle: 7,
            localFileURL: URL(fileURLWithPath: "/tmp/file.txt"),
            type: .upload,
            uploadOptions: UploadOptionsEntity(fileName: "original.txt")
        )
        transfer.setName("file (1).txt")

        #expect(transfer.cancellableTransferEntity.uploadOptions?.fileName == "file (1).txt")
    }

    /// A folder is only away once it reports reaching its transferring stage, where a file is
    /// away as soon as its transfer starts, so the data layer has to be told which it is.
    @Test("An upload of a folder says so")
    func uploadOfAFolder() {
        let transfer = CancellableTransfer(
            parentHandle: 7,
            localFileURL: URL(fileURLWithPath: "/tmp/Docs"),
            isFile: false,
            type: .upload
        )

        #expect(transfer.cancellableTransferEntity.isFile == false)
    }

    // MARK: - Download

    @Test("A download carries its handle, name, app data and priority")
    func download() {
        let transfer = CancellableTransfer(
            handle: 3,
            name: "node.txt",
            appData: "appData",
            priority: true,
            type: .download
        )

        let entity = transfer.cancellableTransferEntity

        #expect(entity.type == .download)
        #expect(entity.handle == 3)
        #expect(entity.name == "node.txt")
        #expect(entity.appData == "appData")
        #expect(entity.startFirst)
    }

    @Test("A download without priority is not queued first")
    func downloadWithoutPriority() {
        let transfer = CancellableTransfer(handle: 3, name: "node.txt", type: .download)

        #expect(transfer.cancellableTransferEntity.startFirst == false)
    }

    // MARK: - Chat download

    @Test("A chat download carries the message it was attached to")
    func chatDownload() {
        let transfer = CancellableTransfer(
            handle: 3,
            messageId: 11,
            chatId: 22,
            name: "node.txt",
            appData: "appData",
            priority: true,
            type: .downloadChat
        )

        let entity = transfer.cancellableTransferEntity

        #expect(entity.type == .downloadChat)
        #expect(entity.handle == 3)
        #expect(entity.messageId == 11)
        #expect(entity.chatId == 22)
        #expect(entity.name == "node.txt")
        #expect(entity.appData == "appData")
        #expect(entity.startFirst)
    }

    // MARK: - File link download

    @Test("A file link download carries the link to follow")
    func fileLinkDownload() throws {
        let link = try #require(URL(string: "https://mega.nz/file/abc"))
        let transfer = CancellableTransfer(
            fileLinkURL: link,
            name: "node.txt",
            priority: true,
            type: .downloadFileLink
        )

        let entity = transfer.cancellableTransferEntity

        #expect(entity.type == .downloadFileLink)
        #expect(entity.fileLinkURL == link)
        #expect(entity.name == "node.txt")
        #expect(entity.startFirst)
    }

    /// The use case leaves it out of the batch; nothing here has to decide that.
    @Test("A file link download without a link carries none rather than refusing")
    func fileLinkDownloadWithoutALink() {
        let transfer = CancellableTransfer(type: .downloadFileLink)

        #expect(transfer.cancellableTransferEntity.fileLinkURL == nil)
    }
}
