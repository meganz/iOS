import Combine
import MEGADomain
import MEGAPresentation

enum OfflineViewAction: ActionType {
    case onViewAppear
    case onViewWillDisappear
    case removeOfflineItems(_ items: [URL])
}

@MainActor
final class OfflineViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadUI
    }
    
    var invokeCommand: ((Command) -> Void)?
    private let transferUseCase: any NodeTransferUseCaseProtocol
    private let offlineUseCase: any OfflineUseCaseProtocol
    private let megaStore: MEGAStore
    private let fileManager: FileManager
    private let documentsDirectoryPath: String?
    private var nodeDownloadMonitoringTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    // MARK: - Init
    init(
        transferUseCase: some NodeTransferUseCaseProtocol,
        offlineUseCase: some OfflineUseCaseProtocol,
        megaStore: MEGAStore,
        fileManager: FileManager = FileManager.default,
        documentsDirectoryPath: String? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    ) {
        self.transferUseCase = transferUseCase
        self.offlineUseCase = offlineUseCase
        self.megaStore = megaStore
        self.fileManager = fileManager
        self.documentsDirectoryPath = documentsDirectoryPath
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: OfflineViewAction) {
        switch action {
        case .onViewAppear:
            startMonitoringNodeDownloadCompletionUpdates()
        case .onViewWillDisappear:
            stopMonitoringNodeDownloadCompletionUpdates()
        case .removeOfflineItems(let items):
            removeOfflineItems(items)
            
        }
    }
    
    // MARK: - Subscriptions
    
    private func startMonitoringNodeDownloadCompletionUpdates() {
        nodeDownloadMonitoringTask = Task { [weak self, transferUseCase] in
            for await _ in transferUseCase.nodeTransferCompletionUpdates.filter({ $0.type == .download }) {
                try Task.checkCancellation()
                self?.invokeCommand?(.reloadUI)
            }
        }
    }
    
    private func stopMonitoringNodeDownloadCompletionUpdates() {
        nodeDownloadMonitoringTask = nil
    }

    /// Removes the specified offline items.
    /// - Parameter items: An array of URLs representing the offline items to be removed.
    private func removeOfflineItems(_ items: [URL]) {
        Task {
            await withTaskGroup(of: Void.self) { [weak self] group in
                for url in items {
                    group.addTask {
                        do {
                            try await self?.offlineUseCase.removeItem(at: url)
                            await self?.removeLogFromSharedSandboxIfNeeded(path: url.path)
                            
                            guard let relativePath = self?.offlineUseCase.relativePathToDocumentsDirectory(for: url) else { return }
                            if url.hasDirectoryPath {
                                await MainActor.run {
                                    self?.megaStore.deleteOfflineAppearancePreference(path: relativePath)
                                }
                            }
                            await MainActor.run {
                                if let offlineNode = self?.megaStore.fetchOfflineNode(withPath: relativePath) {
                                    self?.megaStore.remove(offlineNode)
                                }
                            }
                        } catch {
                            MEGALogError("Remove item at \(url) failed with \(error)")
                        }
                    }
                }
                
                await group.waitForAll()
                
                self?.invokeCommand?(.reloadUI)
                QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAOfflineQuickAccessWidget)
            }
        }
    }

    private func removeLogFromSharedSandboxIfNeeded(path: String) {
        removeLogFromSharedSandbox(path: path, extensionLogName: documentProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: fileProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: shareExtensionLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: notificationServiceExtensionLog)
    }
    
    private func removeLogFromSharedSandbox(path: String, extensionLogName: String) {
        let logsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder).path
        let documentsPath = documentsDirectoryPath?.appending("/")
        let extensionLogFile = documentsPath?.append(pathComponent: extensionLogName)
        if let logsPath, extensionLogFile == path {
            do {
                try fileManager.removeItem(atPath: logsPath.append(pathComponent: extensionLogName))
            } catch {
                MEGALogError("[File manager] remove item at path failed with error \(error)")
            }
        }
    }
}
