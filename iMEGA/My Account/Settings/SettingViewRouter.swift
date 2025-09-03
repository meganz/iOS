import Accounts
import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import Settings
import UIKit

class SettingViewRouter: Routing {
    private weak var presenter: UINavigationController?
    private weak var viewController: UIViewController?
    
    init(presenter: UINavigationController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SettingsTableViewControllerID") as! SettingsTableViewController
        self.viewController = viewController
        let viewModel = SettingsViewModel(router: self, sections: makeSections())
        viewController.viewModel = viewModel
        bindViewModels(vm: viewModel)
        return viewController
    }
    
    func bindViewModels(vm: SettingsViewModel) {
        vm.sectionViewModels.forEach { sectionModel in
            sectionModel.cellViewModels.forEach { cellModel in
                cellModel.invokeCommand = { [weak vm] cmd in
                    switch cmd {
                    case .reloadData:
                        vm?.reloadData()
                    }
                }
            }
        }
    }
    
    func start() {
        let vc = build()
        presenter?.pushViewController(vc, animated: true)
    }
    
    private func createCameraUploadCellViewModel() -> SettingCellViewModel {
        let vm = SettingCellViewModel(image: MEGAAssets.UIImage.cameraUploadsSettings,
                                      title: Strings.Localizable.General.cameraUploads,
                                      displayValue: CameraUploadManager.getCameraUploadStatus(), router: nil)
        let router = CameraUploadsSettingsViewRouter(presenter: presenter, closure: { [weak vm] in
            vm?.updateDisplayValue(CameraUploadManager.getCameraUploadStatus())
        })
        vm.updateRouter(router: router)
        return vm
    }
}

extension SettingViewRouter {
    @SettingBuilder
    private func makeSections() -> [SettingSectionViewModel] {
        
        SettingSectionViewModel {
            createCameraUploadCellViewModel()
            SettingCellViewModel(image: MEGAAssets.UIImage.chatSettings,
                                 title: Strings.Localizable.chat,
                                 router: ChatSettingsViewRouter(presenter: presenter))
            
            SettingCellViewModel(image: MEGAAssets.UIImage.callsSettings,
                                 title: Strings.Localizable.Settings.Section.Calls.title,
                                 router: CallsSettingsViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: MEGAAssets.UIImage.securitySettings,
                                 title: Strings.Localizable.Settings.Section.security,
                                 router: SecuritySettingsViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: MEGAAssets.UIImage.userInterfaceSettings,
                                 title: Strings.Localizable.Settings.Section.userInterface,
                                 router: AppearanceViewRouter(presenter: presenter))
            
            SettingCellViewModel(image: MEGAAssets.UIImage.fileManagementSettings,
                                 title: Strings.Localizable.fileManagement,
                                 router: FileManagementSettingsViewRouter(navigationController: presenter))
            
            SettingCellViewModel(image: MEGAAssets.UIImage.advancedSettings,
                                 title: Strings.Localizable.advanced,
                                 router: AdvancedViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: MEGAAssets.UIImage.helpSettings,
                                 title: Strings.Localizable.help,
                                 router: HelpViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: MEGAAssets.UIImage.aboutSettings,
                                 title: Strings.Localizable.about,
                                 router: AboutViewRouter(presenter: presenter,
                                                         appBundle: .main,
                                                         systemVersion: UIDevice.current.systemVersion,
                                                         deviceName: UIDevice.current.deviceName() ?? ""))
            
            SettingCellViewModel(
                image: MEGAAssets.UIImage.termsAndPoliciesSettings,
                title: Strings.Localizable.Settings.Section.termsAndPolicies,
                router: TermsAndPoliciesRouter(
                    accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                    domainNameHandler: { DIContainer.domainName },
                    navigationController: presenter
                )
            )
            
            SettingCellViewModel(image: MEGAAssets.UIImage.cookieSettings,
                                 title: cookieSettingsMenuTitle(),
                                 router: CookieSettingsRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: nil,
                                 title: Strings.Localizable.cancelYourAccount,
                                 isDestructive: true,
                                 router: DeleteAccountRouter(presenter: viewController))
        }
        
#if DEBUG || QA_CONFIG
        SettingSectionViewModel {
            SettingCellViewModel(image: MEGAAssets.UIImage.iconSettings,
                                 title: "QA Settings",
                                 router: QASettingsRouter(presenter: presenter))
        }
#endif
    }
    
    private func cookieSettingsMenuTitle() -> String {
        guard DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds) &&
            GoogleMobileAdsConsentManager.shared.isPrivacyOptionsRequired else {
            return Strings.Localizable.General.cookieSettings
        }
        return Strings.Localizable.General.cookieAndAdSettings
    }
}

extension SettingSectionViewModel {
    init(@SettingSectionBuilder _ makeCells: () -> [SettingCellViewModel]) {
        self.init(cellViewModels: makeCells())
    }
}
