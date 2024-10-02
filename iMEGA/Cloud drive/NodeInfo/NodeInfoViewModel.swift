import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGARepo

enum NodeInfoAction: ActionType {
    case viewDidLoad
    case viewDidDisappear
}

@objc final class NodeInfoViewModel: NSObject, ViewModelType {

    var invokeCommand: ((Command) -> Void)?
    
    enum Command: CommandType {
        case reloadSections
    }
    
    private let router = SharedItemsViewRouter()
    private let shareUseCase: (any ShareUseCaseProtocol)?
    private let nodeUseCase: any NodeUseCaseProtocol
    private let tracker: any AnalyticsTracking

    let shouldDisplayContactVerificationInfo: Bool

    var node: MEGANode
    var isNodeUndecryptedFolder: Bool
    
    private(set) var nodeInfoLocationViewModel: NodeInfoLocationViewModel?
    private var loadNodeInfoLocationTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    init(
        withNode node: MEGANode,
        shareUseCase: (any ShareUseCaseProtocol)? = nil,
        nodeUseCase: some NodeUseCaseProtocol,
        isNodeUndecryptedFolder: Bool = false,
        shouldDisplayContactVerificationInfo: Bool = false,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        completion: (() -> Void)? = nil
    ) {
        self.shareUseCase = shareUseCase
        self.nodeUseCase = nodeUseCase
        self.node = node
        self.isNodeUndecryptedFolder = isNodeUndecryptedFolder
        self.tracker = tracker
        self.shouldDisplayContactVerificationInfo = shouldDisplayContactVerificationInfo
    }
    
    func dispatch(_ action: NodeInfoAction) {
        switch action {
        case .viewDidLoad:
            loadNodeInfoLocationTask = Task { await loadNodeInfoLocationViewModel() }
            tracker.trackAnalyticsEvent(with: NodeInfoScreenEvent())
        case .viewDidDisappear:
            loadNodeInfoLocationTask = nil
        }
    }
    
    @MainActor
    func loadNodeInfoLocationViewModel() async {
        
        guard
            nodeInfoLocationViewModel == nil,
            node.name?.fileExtensionGroup.isVisualMedia ?? false,
            await nodeUseCase.nodeAccessLevelAsync(nodeHandle: node.handle) == .owner else {
            return
        }
        
        nodeInfoLocationViewModel = NodeInfoLocationViewModel(
            nodeEntity: node.toNodeEntity(),
            geoCoderUseCase: GeoCoderUseCase(geoCoderRepository: GeoCoderRepository.newRepo))
        
        invokeCommand?(.reloadSections)
    }
    
    @MainActor
    func openSharedDialog() async {
        guard node.isFolder() else {
            router.showShareFoldersContactView(withNodes: [node])
            return
        }
        
        do {
            _ = try await shareUseCase?.createShareKeys(forNodes: [node.toNodeEntity()])
            router.showShareFoldersContactView(withNodes: [node])
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
    
    private func trackScreenView() {
        tracker.trackAnalyticsEvent(with: NodeInfoScreenEvent())
    }

    func isContactVerified() -> Bool {
        guard let user = shareUseCase?.user(from: node.toNodeEntity()) else { return false }
        return shareUseCase?.areCredentialsVerifed(of: user) == true
    }

    func openVerifyCredentials(
        from rootNavigationController: UINavigationController,
        completion: @escaping () -> Void
    ) {
        guard let verifyCredentialsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "VerifyCredentialsViewControllerID") as? VerifyCredentialsViewController else {
            return
        }

        let user = shareUseCase?.user(from: node.toNodeEntity())?.toMEGAUser()
        verifyCredentialsVC.user = user
        verifyCredentialsVC.userName = user?.mnz_displayName ?? user?.email

        verifyCredentialsVC.setContactVerification(true)
        verifyCredentialsVC.statusUpdateCompletionBlock = {
            completion()
        }

        let navigationController = MEGANavigationController(rootViewController: verifyCredentialsVC)
        navigationController.addRightCancelButton()
        rootNavigationController.present(navigationController, animated: true)
    }
}
