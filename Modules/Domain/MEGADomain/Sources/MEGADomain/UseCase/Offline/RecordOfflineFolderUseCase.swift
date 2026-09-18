import Foundation
import MEGAFoundation

// MARK: - Use case protocol -

/// Records that a downloaded folder is now saved offline.
///
/// - Important: `@MainActor` because the offline store is backed by the main managed object context.
@MainActor
public protocol RecordOfflineFolderUseCaseProtocol: Sendable {
    /// Records every folder among `transfers` as saved offline
    ///
    /// Items that are not folders are ignored: a file has its own transfer,
    /// and already handled at AppDelegate.onTransferFinish. Check `SaveNodeUseCase` for details
    ///
    /// - Parameter transfers: The transfers of the batch,
    func recordFolders(in transfers: [CancellableTransferEntity])
}

// MARK: - Use case implementation -

@MainActor
public struct RecordOfflineFolderUseCase: RecordOfflineFolderUseCaseProtocol {
    private let offlineFilesRepository: any OfflineFilesRepositoryProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    private let notificationCenter: NotificationCenter

    public init(
        offlineFilesRepository: some OfflineFilesRepositoryProtocol,
        nodeRepository: some NodeRepositoryProtocol,
        notificationCenter: NotificationCenter = .default
    ) {
        self.offlineFilesRepository = offlineFilesRepository
        self.nodeRepository = nodeRepository
        self.notificationCenter = notificationCenter
    }

    public func recordFolders(in transfers: [CancellableTransferEntity]) {
        for transfer in transfers where !transfer.isFile {
            guard case .download = transfer.type, let name = transfer.name else { continue }
            MEGALog.log(level: .info, message: "[CancellableTransfer] recording offline folder \(name)")
            offlineFilesRepository.createOfflineFile(name: name, for: transfer.handle)
            notificationCenter.post(name: .nodeSavedToOffline, object: nodeRepository.nodeForHandle(transfer.handle))
        }
    }
}
