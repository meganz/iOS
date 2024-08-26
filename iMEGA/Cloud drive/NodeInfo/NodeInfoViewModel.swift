import MEGADomain
import MEGAPresentation
import MEGARepo

@objc final class NodeInfoViewModel: NSObject {
    private let router = SharedItemsViewRouter()
    private let shareUseCase: (any ShareUseCaseProtocol)?
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    let shouldDisplayContactVerificationInfo: Bool

    var node: MEGANode
    var isNodeUndecryptedFolder: Bool

    var shouldShowNodeDescription: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .nodeDescription)
    }
    
    private(set) lazy var nodeInfoLocationViewModel: NodeInfoLocationViewModel? = {
        guard node.name?.fileExtensionGroup.isVisualMedia ?? false else {
            return nil
        }
        return NodeInfoLocationViewModel(
            nodeEntity: node.toNodeEntity(),
            geoCoderUseCase: GeoCoderUseCase(geoCoderRepository: GeoCoderRepository.newRepo))
    }()

    init(
        withNode node: MEGANode,
        shareUseCase: (any ShareUseCaseProtocol)? = nil,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        isNodeUndecryptedFolder: Bool = false,
        shouldDisplayContactVerificationInfo: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        self.shareUseCase = shareUseCase
        self.node = node
        self.featureFlagProvider = featureFlagProvider
        self.isNodeUndecryptedFolder = isNodeUndecryptedFolder
        self.shouldDisplayContactVerificationInfo = shouldDisplayContactVerificationInfo
    }
    
    @MainActor
    func openSharedDialog() {
        guard node.isFolder() else {
            router.showShareFoldersContactView(withNodes: [node])
            return
        }
        
        Task {
            do {
                _ = try await shareUseCase?.createShareKeys(forNodes: [node.toNodeEntity()])
                router.showShareFoldersContactView(withNodes: [node])
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
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
