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
                cellModel.invokeCommand =  { [weak vm] cmd in
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
        let vm = SettingCellViewModel(image: Asset.Images.Settings.cameraUploadsSettings,
                             title: Strings.Localizable.cameraUploadsLabel,
                                      displayValue: CameraUploadManager.getCameraUploadStatus())
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
            SettingCellViewModel(image: Asset.Images.Settings.chatSettings,
                                 title: Strings.Localizable.chat,
                                 router: ChatSettingsViewRouter(presenter: presenter))
                
            SettingCellViewModel(image: Asset.Images.Settings.callsSettings,
                                 title: Strings.Localizable.Settings.Section.Calls.title,
                                 router: CallsSettingsViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: Asset.Images.Settings.securitySettings,
                                 title: Strings.Localizable.Settings.Section.security,
                                 router: SecuritySettingsViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: Asset.Images.Settings.userInterfaceSettings,
                                 title: Strings.Localizable.Settings.Section.userInterface,
                                 router: AppearanceViewRouter(presenter: presenter))
            
            SettingCellViewModel(image: Asset.Images.Settings.fileManagementSettings,
                                 title: Strings.Localizable.fileManagement,
                                 router: FileManagementSettingsViewRouter(presenter: presenter))
            
            SettingCellViewModel(image: Asset.Images.Settings.advancedSettings,
                                 title: Strings.Localizable.advanced,
                                 router: AdvancedViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: Asset.Images.Settings.helpSettings,
                                 title: Strings.Localizable.help,
                                 router: HelpViewRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: Asset.Images.Settings.aboutSettings,
                                 title: Strings.Localizable.about,
                                 router: AboutViewRouter(presenter: presenter))
            
            SettingCellViewModel(image: Asset.Images.Settings.termsAndPoliciesSettings,
                                 title: Strings.Localizable.Settings.Section.termsAndPolicies,
                                 router: TermsAndPoliciesRouter(presentController: presenter))
            
            SettingCellViewModel(image: Asset.Images.Settings.cookieSettings,
                                 title: Strings.Localizable.General.cookieSettings,
                                 router: CookieSettingsRouter(presenter: presenter))
        }
        
        SettingSectionViewModel {
            SettingCellViewModel(image: nil,
                                 title: Strings.Localizable.cancelYourAccount,
                                 isDestructive: true,
                                 router: DeleteAccountRouter(presenter: viewController))
        }
        
#if QA_CONFIG
        SettingSectionViewModel {
            SettingCellViewModel(image: Asset.Images.MyAccount.iconSettings,
                                 title: "QA Settings",
                                 router: QASettingsRouter(presenter: presenter))
        }
#endif
    }
}

extension SettingSectionViewModel {
    init(@SettingSectionBuilder _ makeCells: () -> [SettingCellViewModel]) {
        self.init(cellViewModels: makeCells())
    }
}
