import Foundation

enum QuickAccessWidgetAction: ActionType {
    case managePendingAction
    case showOffline
    case showRecents
    case showOfflineFile(String)
}

final class QuickAccessWidgetViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case selectOfflineTab
        case selectRecentsTab
        case presentOfflineFileWithPath(String)
    }
    
    // MARK: - Private properties
    private let offlineFilesUseCase: OfflineFilesUseCaseProtocol
    private var pendingQuickAccessWidgetAction: QuickAccessWidgetAction?

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    init(offlineFilesUseCase: OfflineFilesUseCaseProtocol) {
        self.offlineFilesUseCase = offlineFilesUseCase;
    }
    
    func dispatch(_ action: QuickAccessWidgetAction) {
        if let invokeCommand = invokeCommand {
            switch action {
            case .managePendingAction:
                guard let pendingAction = pendingQuickAccessWidgetAction else {
                    return
                }
                dispatch(pendingAction)
            case .showOffline:
                invokeCommand(.selectOfflineTab)
            case .showRecents:
                invokeCommand(.selectRecentsTab)
            case .showOfflineFile(let base64Handle):
                invokeCommand(.selectOfflineTab)
                guard let path = offlineFilesUseCase.offlineFile(for: base64Handle)?.localPath else {
                    return
                }
                invokeCommand(.presentOfflineFileWithPath(path))
            }
        } else {
            pendingQuickAccessWidgetAction = action
        }
    }
}
