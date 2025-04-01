import MEGAAppPresentation
import MEGADomain
import MEGASdk
import MEGASDKRepo

/// Routing the app to show the quick upload actions at CD's root.
@objc final class CloudDriveQuickUploadActionRouter: NSObject {
    let navigationController: UINavigationController
    let uploadAddMenuDelegateHandler: any UploadAddMenuDelegate
    let contextMenuManager: ContextMenuManager
    let viewModeProvider: () -> ViewModePreferenceEntity?
    
    init(
        navigationController: UINavigationController,
        uploadAddMenuDelegateHandler: any UploadAddMenuDelegate,
        contextMenuManager: ContextMenuManager,
        viewModeProvider: @escaping () -> ViewModePreferenceEntity?
    ) {
        self.navigationController = navigationController
        self.uploadAddMenuDelegateHandler = uploadAddMenuDelegateHandler
        self.contextMenuManager = contextMenuManager
        self.viewModeProvider = viewModeProvider
        super.init()
    }
    
    func build() -> UIViewController? {
        let config = CMConfigEntity(menuType: .menu(type: .uploadAdd), viewMode: viewModeProvider())
        guard let actions = contextMenuManager.actionSheetActions(with: config) else { return nil }
        return ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
    }
    
    func start() {
        guard let actionSheetVC = build() else { return }
        navigationController.present(actionSheetVC, animated: true)
    }
}
