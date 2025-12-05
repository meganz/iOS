import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAPermissions
import MEGAPreference
import MEGARepo
import SwiftUI

@MainActor
protocol CameraUploadProgressRouting {
    func start(onCameraUploadSettingsChanged: (() -> Void)?)
    func showUpgradeAccount()
    func showCameraUploadSettings()
}

final class CameraUploadProgressRouter: CameraUploadProgressRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    
    private var cameraUploadSettingsChanged: (() -> Void)?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let assetRepository = CameraUploadAssetRepository(
            cameraUploadRecordStore: CameraUploadRecordManager.shared())
        let preferenceRepository = PreferenceRepository.newRepo
        let preferenceUseCase = PreferenceUseCase(repository: preferenceRepository)
        let viewModel = CameraUploadProgressViewModel(
            monitorCameraUploadUseCase: MonitorCameraUploadUseCase(
                cameraUploadRepository: CameraUploadsStatsRepository.newRepo,
                networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                preferenceUseCase: PreferenceUseCase(
                    repository: preferenceRepository)),
            cameraUploadProgressUseCase: CameraUploadProgressUseCase(
                cameraUploadAssetRepository: assetRepository,
                transferProgressRepository: CameraUploadTransferProgressRepository.shared),
            cameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCase(
                cameraUploadAssetRepository: assetRepository,
                cameraAssetTypeRepository: CameraAssetTypeRepository(),
                preferenceRepository: preferenceRepository),
            photoLibraryThumbnailProvider: PhotoLibraryThumbnailProvider(),
            queuedCameraUploadsUseCase: QueuedCameraUploadsUseCase(
                cameraUploadAssetRepository: assetRepository,
                preferenceRepository: preferenceRepository),
            preferenceUseCase: preferenceUseCase,
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: preferenceUseCase),
            cameraUploadProgressRouter: self,
            devicePermissionHandler: DevicePermissionsHandler.makeHandler())
        
        let hostingController = UIHostingController(
            rootView: CameraUploadProgressView(viewModel: viewModel))
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.view.backgroundColor = TokenColors.Background.page
        
        baseViewController = hostingController
        
        return hostingController
    }
    
    func start(onCameraUploadSettingsChanged: (() -> Void)?) {
        cameraUploadSettingsChanged = onCameraUploadSettingsChanged
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    func showUpgradeAccount() {
        let accountUseCase = AccountUseCase(
            repository: AccountRepository.newRepo)
        guard let currentAccountDetails = accountUseCase.currentAccountDetails else {
            return
        }
        SubscriptionPurchaseRouter(
            presenter: baseViewController,
            currentAccountDetails: currentAccountDetails,
            viewType: .upgrade,
            accountUseCase: accountUseCase)
        .start()
    }
    
    func showCameraUploadSettings() {
        let storyboard = UIStoryboard(name: "CameraUploadSettings", bundle: nil)
        guard let cameraUploadSettingsVC = storyboard.instantiateViewController(
            withIdentifier: "CameraUploadsSettingsID") as? CameraUploadsTableViewController else { return }
        cameraUploadSettingsVC.cameraUploadSettingChanged = { [weak self] in
            self?.cameraUploadSettingsChanged?()
            self?.baseViewController?.presentingViewController?.dismiss(animated: true)
        }
        cameraUploadSettingsVC.isPresentedModally = true
        let navigationController = MEGANavigationController(rootViewController: cameraUploadSettingsVC)
        navigationController.modalPresentationStyle = .fullScreen
        baseViewController?.present(navigationController, animated: true)
    }
}
