import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

/// Covers which items of a download batch get an offline record, and what is announced when one is
/// written. Whether the batch has reached the point of writing them is the caller's decision.
@Suite("RecordOfflineFolderUseCase Tests")
@MainActor
struct RecordOfflineFolderUseCaseTests {

    // MARK: - Helpers

    private func makeSUT(
        offlineFilesRepository: MockOfflineFilesRepository = MockOfflineFilesRepository(),
        node: NodeEntity? = nil,
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> RecordOfflineFolderUseCase {
        RecordOfflineFolderUseCase(
            offlineFilesRepository: offlineFilesRepository,
            nodeRepository: MockNodeRepository(node: node),
            notificationCenter: notificationCenter
        )
    }

    /// The offline files recorded for `transfers`, as the "name:handle" pair each was written with.
    private func recorded(_ transfers: [CancellableTransferEntity]) -> [String] {
        let offlineFilesRepository = MockOfflineFilesRepository()

        makeSUT(offlineFilesRepository: offlineFilesRepository).recordFolders(in: transfers)

        return offlineFilesRepository.createdOfflineFiles.map { "\($0.name):\($0.handle)" }
    }

    // MARK: - What gets recorded

    @Test("A folder of the batch is recorded offline")
    func aFolderIsRecorded() {
        // The SDK creates no transfer for a folder item, so nothing else writes its row.
        #expect(recorded([.init(handle: 5, isFile: false, type: .download, name: "Docs")]) == ["Docs:5"])
    }

    @Test("A file of the batch is not recorded offline")
    func aFileIsNotRecorded() {
        // Its own transfer finishing is what records a file, so recording it here would duplicate.
        #expect(recorded([.init(handle: 5, isFile: true, type: .download, name: "photo.jpg")]).isEmpty)
    }

    @Test("Every folder of the batch is recorded, and only the folders")
    func everyFolderIsRecorded() {
        let transfers: [CancellableTransferEntity] = [
            .init(handle: 5, isFile: false, type: .download, name: "Docs"),
            .init(handle: 6, isFile: true, type: .download, name: "photo.jpg"),
            .init(handle: 7, isFile: false, type: .download, name: "Photos")
        ]

        #expect(recorded(transfers) == ["Docs:5", "Photos:7"])
    }

    @Test("A chat or file link folder is not recorded offline")
    func onlyANodeDownloadIsRecorded() throws {
        // Neither is ever a folder today, and neither is saved under the node it would be keyed by.
        let link = try #require(URL(string: "https://mega.nz/folder/abc#key"))
        let transfers: [CancellableTransferEntity] = [
            .init(handle: 5, messageId: 6, chatId: 7, isFile: false, type: .downloadChat, name: "Chat"),
            .init(fileLinkURL: link, isFile: false, type: .downloadFileLink, name: "Link")
        ]

        #expect(recorded(transfers).isEmpty)
    }

    @Test("A folder with no name to store it under is not recorded offline")
    func aFolderWithoutANameIsNotRecorded() {
        // The name is the path the row is keyed by, so there is nothing to write without it.
        #expect(recorded([.init(handle: 5, isFile: false, type: .download, name: nil)]).isEmpty)
    }

    @Test("An empty batch records nothing")
    func anEmptyBatchRecordsNothing() {
        #expect(recorded([]).isEmpty)
    }

    // MARK: - Announcing the recorded folder

    @Test("Recording a folder announces the node, so the screens listing it refresh")
    func recordingAFolderAnnouncesTheNode() {
        let notificationCenter = NotificationCenter()
        let folder = NodeEntity(handle: 5)
        let announced = Announcements(of: .nodeSavedToOffline, on: notificationCenter)

        makeSUT(node: folder, notificationCenter: notificationCenter)
            .recordFolders(in: [.init(handle: 5, isFile: false, type: .download, name: "Docs")])

        #expect(announced.nodes == [folder])
    }

    @Test("Nothing is announced when nothing was recorded")
    func nothingIsAnnouncedWithoutAFolder() {
        let notificationCenter = NotificationCenter()
        let announced = Announcements(of: .nodeSavedToOffline, on: notificationCenter)

        makeSUT(node: NodeEntity(handle: 5), notificationCenter: notificationCenter)
            .recordFolders(in: [.init(handle: 5, isFile: true, type: .download, name: "photo.jpg")])

        #expect(announced.nodes.isEmpty)
    }
}

/// The nodes announced on a notification centre, in the order they were posted.
private final class Announcements: @unchecked Sendable {
    @Atomic var nodes = [NodeEntity]()
    private var observer: (any NSObjectProtocol)?

    init(of name: Notification.Name, on notificationCenter: NotificationCenter) {
        observer = notificationCenter.addObserver(forName: name, object: nil, queue: nil) { [weak self] notification in
            guard let node = notification.object as? NodeEntity else { return }
            self?.$nodes.mutate { $0.append(node) }
        }
    }
}
