import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

public protocol MyAccountHallRouting: Routing {
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterAssets: DeviceCenterAssets)
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void)
    func didTapRenameAction(_ renameEntity: RenameActionEntity)
    func didTapNodeAction(type: DeviceCenterActionType, node: NodeEntity)
}

final class MyAccountHallRouter: MyAccountHallRouting {
    private let myAccountHallUseCase: any MyAccountHallUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let shouldOpenAchievements: Bool
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    
    init(
        myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        shouldOpenAchievements: Bool = false,
        navigationController: UINavigationController
    ) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.purchaseUseCase = purchaseUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.shouldOpenAchievements = shouldOpenAchievements
        self.navigationController = navigationController
    }
    
    private func didTapShowInBackupsAction(
        _ node: NodeEntity
    ) {
        guard let backupViewController = self.createCloudDriveVCForNode(node, isBackup: true) else { return }
        
        self.navigationController?.pushViewController(backupViewController, animated: true)
    }
    
    private func didTapShowInCloudDriveAction(
        _ node: NodeEntity
    ) {
        guard let backupViewController = self.createCloudDriveVCForNode(node, isBackup: false) else { return }
        
        self.navigationController?.pushViewController(backupViewController, animated: true)
    }
    
    private func createCloudDriveVCForNode(
        _ node: NodeEntity,
        isBackup: Bool
    ) -> CloudDriveViewController? {
        guard let node = node.toMEGANode(in: MEGASdk.shared),
              let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController else { return nil }
        
        cloudDriveVC.parentNode = node
        cloudDriveVC.displayMode = isBackup ? .backup : .cloudDrive
        return cloudDriveVC
    }
    
    func build() -> UIViewController {
        guard let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
                .instantiateViewController(withIdentifier: "MyAccountHall") as? MyAccountHallViewController else {
            return UIViewController()
        }
        
        let viewModel = MyAccountHallViewModel(
            myAccountHallUseCase: myAccountHallUseCase,
            purchaseUseCase: purchaseUseCase,
            deviceCenterBridge: DeviceCenterBridge(),
            router: self
        )
        
        myAccountViewController.viewModel = viewModel
        
        if shouldOpenAchievements {
            myAccountViewController.openAchievements()
        }
        
        viewController = myAccountViewController
        
        return myAccountViewController
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func navigateToDeviceCenter(
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterAssets: DeviceCenterAssets
    ) {
        DeviceListViewRouter(
            navigationController: navigationController,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterUseCase:
                DeviceCenterUseCase(
                    deviceCenterRepository:
                        DeviceCenterRepository.newRepo
                ),
            nodeUseCase:
                NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                ),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            notificationCenter: NotificationCenter.default,
            deviceCenterAssets: deviceCenterAssets
        ).start()
    }
    
    func didTapCameraUploadsAction(
        statusChanged: @escaping () -> Void
    ) {
        guard let presenter = self.navigationController else { return }

        CameraUploadsSettingsViewRouter(
            presenter: presenter,
            closure: {
                statusChanged()
        }).start()
    }
    
    func didTapRenameAction(
        _ renameEntity: RenameActionEntity
    ) {
        guard let presenter = self.navigationController else { return }
        
        RenameRouter(
            presenter: presenter,
            type: .device(
                renameEntity: renameEntity
            ),
            renameUseCase:
                RenameUseCase(
                    renameRepository: RenameRepository.newRepo
                )
        ).start()
    }
    
    func executeNodeAction(
        for node: NodeEntity,
        action: @escaping (UIViewController, NodeEntity) -> Void
    ) {
        guard networkMonitorUseCase.isConnected() else {
            SVProgressHUD.show(
                UIImage.hudForbidden,
                status: Strings.Localizable.noInternetConnection
            )
            return
        }
        guard let presenter = self.navigationController?.topViewController else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            action(presenter, node)
        }
    }
    
    func didTapShareLinkAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            guard let node = node.toMEGANode(in: MEGASdk.shared) else { return }
            GetLinkRouter(
                presenter: presenter,
                nodes: [node]
            ).start()
        }
    }

    func didTapRemoveLinkAction(
        _ node: NodeEntity
    ) {
        executeNodeAction(for: node) { presenter, node in
            ActionWarningViewRouter(
                presenter: presenter,
                nodes: [node],
                actionType: .removeLink,
                onActionStart: {
                    SVProgressHUD.show()
                }, onActionFinish: {
                    switch $0 {
                    case .success(let message):
                        SVProgressHUD.showSuccess(withStatus: message)
                    case .failure:
                        SVProgressHUD.dismiss()
                    }
                }
            ).start()
        }
    }
    
    func didTapNodeAction(type: DeviceCenterActionType, node: NodeEntity) {
        switch type {
        case .showInCloudDrive: didTapShowInCloudDriveAction(node)
        case .shareLink, .manageLink: didTapShareLinkAction(node)
        case .removeLink: didTapRemoveLinkAction(node)
        default: break
        }
    }
}
