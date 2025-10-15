import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGASwift

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
    private let throttler: any Throttleable
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
        offlineUseCase: some OfflineUseCaseProtocol,
        megaStore: MEGAStore,
        fileManager: FileManager = FileManager.default,
        documentsDirectoryPath: String? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
        throttler: some Throttleable = Throttler(timeInterval: 1.0)
    ) {
        self.offlineUseCase = offlineUseCase
        self.megaStore = megaStore
        self.fileManager = fileManager
        self.documentsDirectoryPath = documentsDirectoryPath
        self.throttler = throttler
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
        nodeDownloadMonitoringTask = Task { [weak self, offlineUseCase] in
            for await _ in offlineUseCase.nodeDownloadCompletionUpdates {
                try Task.checkCancellation()
                self?.throttler.start { @Sendable in
                    Task { @MainActor in
                        self?.invokeCommand?(.reloadUI)
                    }
                }
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
            await items.taskGroup(maxConcurrentTasks: 3) { url in
                await self.removeOfflineItem(url: url)
            }
            
            invokeCommand?(.reloadUI)
            QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAOfflineQuickAccessWidget)
        }
    }
    
    private func removeOfflineItem(url: URL) async {
        do {
            try await offlineUseCase.removeItem(at: url)
            removeLogFromSharedSandboxIfNeeded(path: url.path)
            let relativePath = offlineUseCase.relativePathToDocumentsDirectory(for: url)
            if url.hasDirectoryPath {
                megaStore.deleteOfflineAppearancePreference(path: relativePath)
            }
            if let offlineNode = megaStore.fetchOfflineNode(withPath: relativePath) {
                megaStore.remove(offlineNode)
            }
        } catch {
            MEGALogError("Remove item at \(url) failed with \(error)")
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
