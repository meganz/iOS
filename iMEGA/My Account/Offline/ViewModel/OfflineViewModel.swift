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
    private var nodeDownloadMonitoringTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    // MARK: - Init
    init(
        transferUseCase: some NodeTransferUseCaseProtocol,
        offlineUseCase: some OfflineUseCaseProtocol,
        megaStore: MEGAStore
    ) {
        self.transferUseCase = transferUseCase
        self.offlineUseCase = offlineUseCase
        self.megaStore = megaStore
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
        items.forEach { url in
            do {
                try offlineUseCase.removeItem(at: url)
                removeLogFromSharedSandboxIfNeeded(path: url.path)
                
                let relativePath = offlineUseCase.relativePathToDocumentsDirectory(for: url)
                if url.hasDirectoryPath {
                    megaStore.deleteOfflineAppearancePreference(path: relativePath)
                }
                
                if let offlineNode = megaStore.fetchOfflineNode(withPath: relativePath) {
                    megaStore.remove(offlineNode)
                }
            } catch {
                MEGALogError("Remote item at \(url) failed with \(error)")
            }
        }
        invokeCommand?(.reloadUI)
        QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAOfflineQuickAccessWidget)
    }
    
    private func removeLogFromSharedSandboxIfNeeded(path: String) {
        removeLogFromSharedSandbox(path: path, extensionLogName: documentProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: fileProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: shareExtensionLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: notificationServiceExtensionLog)
    }
    
    private func removeLogFromSharedSandbox(path: String, extensionLogName: String) {
        let logsPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder).path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/")
        let extensionLogFile = documentsPath?.append(pathComponent: extensionLogName)
        if let logsPath, extensionLogFile == path {
            do {
                try FileManager.default.removeItem(atPath: logsPath.append(pathComponent: extensionLogName))
            } catch {
                MEGALogError("[File manager] remove item at path failed with error \(error)")
            }
        }
    }
}
