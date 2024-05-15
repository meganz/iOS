import Combine
import MEGADomain
import MEGAPresentation

enum OfflineViewAction: ActionType {
    case addSubscriptions
    case removeSubscriptions
    case removeOfflineItems(_ items: [URL])
}

final class OfflineViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadUI
    }
    
    var invokeCommand: ((Command) -> Void)?
    private let transferUseCase: any NodeTransferUseCaseProtocol
    private let offlineUseCase: any OfflineUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()
    private let megaStore: MEGAStore
    
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
        case .addSubscriptions:
            registerTransferDelegates()
        case .removeSubscriptions:
            deRegisterTransferDelegates()
        case .removeOfflineItems(let items):
            removeOfflineItems(items)
            
        }
    }
    
    // MARK: - Subscriptions
    
    private func registerTransferDelegates() {
        Task { [weak self] in
            guard let self else { return }
            await transferUseCase.registerMEGATransferDelegate()
            await transferUseCase.registerMEGASharedFolderTransferDelegate()
            setUpSubscription()
        }
    }
    
    private func deRegisterTransferDelegates() {
        Task.detached { [weak self] in
            guard let self else { return }
            await transferUseCase.deRegisterMEGATransferDelegate()
            await transferUseCase.deRegisterMEGASharedFolderTransferDelegate()
            subscriptions.removeAll()
        }
    }
    
    private func setUpSubscription() {
        transferUseCase.transferResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                handleTransferResult(result)
            }
            .store(in: &subscriptions)
    }
    
    private func handleTransferResult(_ result: Result<TransferEntity, TransferErrorEntity>) {
        guard case .success(let request) = result,
              request.type == .download else {
            return
        }
        invokeCommand?(.reloadUI)
    }
    
    /// Removes the specified offline items.
    /// - Parameter items: An array of URLs representing the offline items to be removed.
    private func removeOfflineItems(_ items: [URL]) {
        items.forEach { url in
            offlineUseCase.removeItem(at: url)
            removeLogFromSharedSandboxIfNeeded(path: url.path)
            
            let relativePath = offlineUseCase.relativePathToDocumentsDirectory(for: url)
            if url.hasDirectoryPath {
                megaStore.deleteOfflineAppearancePreference(path: relativePath)
            }
            
            if let offlineNode = megaStore.fetchOfflineNode(withPath: relativePath) {
                megaStore.remove(offlineNode)
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
