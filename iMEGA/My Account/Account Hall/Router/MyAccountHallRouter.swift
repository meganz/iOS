import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

public protocol MyAccountHallRouting: Routing {
    func navigateToDeviceCenter(deviceCenterBridge: DeviceCenterBridge, deviceCenterAssets: DeviceCenterAssets)
    func didTapCameraUploadsAction(statusChanged: @escaping () -> Void)
    func didTapRenameAction(_ renameEntity: RenameActionEntity)
    func didTapInfoAction(_ infoModel: ResourceInfoModel)
    func didTapNavigateToContent(_ navigateToContentEntity: NavigateToContentActionEntity)
}

final class MyAccountHallRouter: MyAccountHallRouting {
    private let myAccountHallUseCase: any MyAccountHallUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let shareUseCase: any ShareUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let shouldOpenAchievements: Bool
    private weak var navigationController: UINavigationController?
    private weak var viewController: UIViewController?
    private let loadingPresenter: () -> Void
    private let actionSucceededPresenter: (String) -> Void
    private let dismissLoadingPresenter: () -> Void
    private let noInternetConnectionPresenter: (UIImage, String) -> Void
    
    init(
        myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        shareUseCase: some ShareUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        shouldOpenAchievements: Bool = false,
        navigationController: UINavigationController,
        loadingPresenter: @escaping () -> Void = { SVProgressHUD.show() },
        actionSucceededPresenter: @escaping (String) -> Void = { SVProgressHUD.showSuccess(withStatus: $0) },
        dismissLoadingPresenter: @escaping () -> Void = { SVProgressHUD.dismiss() },
        noInternetConnectionPresenter: @escaping (UIImage, String) -> Void = { SVProgressHUD.show($0, status: $1) }
    ) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.purchaseUseCase = purchaseUseCase
        self.shareUseCase = shareUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.shouldOpenAchievements = shouldOpenAchievements
        self.navigationController = navigationController
        self.loadingPresenter = loadingPresenter
        self.actionSucceededPresenter = actionSucceededPresenter
        self.dismissLoadingPresenter = dismissLoadingPresenter
        self.noInternetConnectionPresenter = noInternetConnectionPresenter
    }
    
    @MainActor
    private func pushCDViewController(
        _ node: NodeEntity, 
        isBackup: Bool,
        warningMessage: String? = nil
    ) {
        guard let viewController = self.createCloudDriveVCForNode(
            node,
            isBackup: isBackup,
            warningMessage: warningMessage
        ) else { return }
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func didTapShowInBackupsAction(
        _ node: NodeEntity,
        warningMessage: String?
    ) {
        Task {
            await pushCDViewController(
                node,
                isBackup: true,
                warningMessage: warningMessage
            )
        }
    }

    private func didTapShowInCloudDriveAction(
        _ node: NodeEntity,
        warningMessage: String?
    ) {
        Task {
            await pushCDViewController(
                node,
                isBackup: false,
                warningMessage: warningMessage
            )
        }
    }
    
    private func createCloudDriveVCForNode(
        _ node: NodeEntity,
        isBackup: Bool,
        warningMessage: String?
    ) -> UIViewController? {
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        
        let warningViewModel =
            warningMessage != nil ?
                WarningViewModel(warningType: .backupStatusError(warningMessage ?? "")): nil
        
        return factory.buildBare(
            parentNode: node,
            config: .init(
                displayMode: isBackup ? .backup : .cloudDrive,
                warningViewModel: warningViewModel
            )
        )
    }
    
    private func setupContactsViewController(with node: NodeEntity, mode: ContactsMode) -> ContactsViewController? {
        guard let node = node.toMEGANode(in: MEGASdk.shared),
              let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(identifier: "ContactsViewControllerID") as? ContactsViewController else {
            return nil
        }
        
        contactsVC.node = node
        contactsVC.contactsMode = mode
        return contactsVC
    }
    
    private func executeNodeAction(
        for node: NodeEntity,
        action: @escaping (UIViewController, NodeEntity) -> Void
    ) {
        guard networkMonitorUseCase.isConnected() else {
            noInternetConnectionPresenter(
                UIImage.hudForbidden,
                Strings.Localizable.noInternetConnection
            )
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self,
                  let presenter = self.navigationController?.topViewController else { return }
            action(presenter, node)
        }
    }
    
    func build() -> UIViewController {
        guard let myAccountViewController = UIStoryboard(name: "MyAccount", bundle: nil)
                .instantiateViewController(withIdentifier: "MyAccountHall") as? MyAccountHallViewController else {
            return UIViewController()
        }
        
        let viewModel = MyAccountHallViewModel(
            myAccountHallUseCase: myAccountHallUseCase,
            purchaseUseCase: purchaseUseCase, 
            shareUseCase: shareUseCase,
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
            cameraUploadsUseCase:
                CameraUploadsUseCase(
                    cameraUploadsRepository: CameraUploadsRepository.newRepo
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self,
                  let presenter = self.navigationController else { return }
            
            RenameRouter(
                presenter: presenter,
                renameEntity: renameEntity,
                renameUseCase: RenameUseCase(
                    renameRepository: RenameRepository.newRepo
                )
            ).start()
        }
    }
    
    func didTapInfoAction(
        _ infoModel: ResourceInfoModel
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self,
                  let presenter = self.navigationController else { return }
            
            ResourceInfoViewRouter(
                presenter: presenter,
                infoModel: infoModel
            ).start()
        }
    }
    
    func didTapNavigateToContent(_ navigateToContentEntity: NavigateToContentActionEntity) {
        switch navigateToContentEntity.type {
        case .showInCloudDrive:
            didTapShowInCloudDriveAction(
                navigateToContentEntity.node,
                warningMessage: navigateToContentEntity.error
            )
        case .showInBackups:
            didTapShowInBackupsAction(
                navigateToContentEntity.node,
                warningMessage: navigateToContentEntity.error
            )
        default: break
        }
        
    }
}
