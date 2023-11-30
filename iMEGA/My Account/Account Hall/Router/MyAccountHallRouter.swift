import DeviceCenter
import MEGADomain
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
    private let shouldOpenAchievements: Bool
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    
    init(
        myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        shouldOpenAchievements: Bool = false,
        navigationController: UINavigationController
    ) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.purchaseUseCase = purchaseUseCase
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
    
    private func createCloudDriveVCForNode(_ node: NodeEntity, isBackup: Bool) -> CloudDriveViewController? {
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
    
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void) {
        guard let presenter = self.navigationController else { return }

        CameraUploadsSettingsViewRouter(
            presenter: presenter,
            closure: {
                statusChanged()
        }).start()
    }
    
    func didTapRenameAction(_ renameEntity: RenameActionEntity) {
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
    
    func didTapNodeAction(type: DeviceCenterActionType, node: NodeEntity) {
        switch type {
        case .showInCloudDrive: didTapShowInCloudDriveAction(node)
        default: break
        }
    }
}
