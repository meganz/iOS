import UIKit
import MEGAPresentation
import MEGADomain
import Settings

class SettingViewRouter: Routing {
    private weak var presenter: UINavigationController?
    private weak var viewController: UIViewController?
    
    private enum Constants {
        static let bundleSortVersionKey = "CFBundleShortVersionString"
        static let sdkGitCommitHashKey = "SDK_GIT_COMMIT_HASH"
        static let chatSdkGitCommitHashKey = "CHAT_SDK_GIT_COMMIT_HASH"
        
        static let sourceCodeURL = "https://github.com/meganz/iOS"
        static let acknowledgementsURL = "https://github.com/meganz/iOS3/blob/master/CREDITS.md"
    }
    
    private lazy var appVersion: String = {
        guard let bundleShortVersion = Bundle.main.infoDictionary?[Constants.bundleSortVersionKey] as? String,
              let bundleVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String else { return "" }
        
        return "\(bundleShortVersion) (\(bundleVersion))"
    }()
    
    private lazy var sdkVersion: String = {
        Bundle.main.infoDictionary?[Constants.sdkGitCommitHashKey] as? String ?? ""
    }()
    
    private lazy var chatSdkVersion: String = {
        Bundle.main.infoDictionary?[Constants.chatSdkGitCommitHashKey] as? String ?? ""
    }()
    
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
        let vm = SettingCellViewModel(image: Asset.Images.Settings.cameraUploadsSettings,
                                      title: Strings.Localizable.cameraUploadsLabel,
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
                                 router: AboutViewRouter(presenter: presenter,
                                                         aboutViewModel: AboutViewModel(preferenceUC: PreferenceUseCase.default,
                                                                                        apiEnvironmentUC: APIEnvironmentUseCase(repository: APIEnvironmentRepository.newRepo),
                                                                                        manageLogsUC: ManageLogsUseCase(repository: LogSettingRepository.newRepo,
                                                                                                                        preferenceUseCase: PreferenceUseCase.default),
                                                                                        aboutSetting: makeAboutSetting()),
                                                         title: Strings.Localizable.about))
            
            SettingCellViewModel(image: Asset.Images.Settings.termsAndPoliciesSettings,
                                 title: Strings.Localizable.Settings.Section.termsAndPolicies,
                                 router: TermsAndPoliciesRouter(navigationController: presenter))
            
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
    
    private func makeAboutSetting() -> AboutSetting {
        AboutSetting(
            appVersion:
                AppVersion(
                    title: Strings.Localizable.appVersion,
                    message: appVersion
                ),
            sdkVersion:
                AppVersion(
                    title: Strings.Localizable.sdkVersion,
                    message: sdkVersion
                ),
            chatSDKVersion:
                AppVersion(
                    title: Strings.Localizable.megachatSdkVersion,
                    message: chatSdkVersion
                ),
            viewSourceLink:
                SettingsLink(
                    title: Strings.Localizable.viewSourceCode,
                    url: URL(string: Constants.sourceCodeURL) ?? URL(fileURLWithPath: "")
                ),
            acknowledgementsLink:
                SettingsLink(
                    title: Strings.Localizable.acknowledgements,
                    url: URL(string: Constants.acknowledgementsURL) ?? URL(fileURLWithPath: "")
                ),
            apiEnvironment:
                APIEnvironmentChangingAlert(
                    title: Strings.Localizable.changeToATestServer,
                    message: Strings.Localizable.areYouSureYouWantToChangeToATestServerYourAccountMaySufferIrrecoverableProblems,
                    cancelActionTitle: Strings.Localizable.cancel,
                    actions: [
                        APIEnvironment(
                            title: APIEnvironmentEntity.production.rawValue,
                            environment: .production
                        ),
                        APIEnvironment(
                            title: APIEnvironmentEntity.staging.rawValue,
                            environment: .staging
                        ),
                        APIEnvironment(
                            title: APIEnvironmentEntity.staging444.rawValue,
                            environment: .staging444
                        ),
                        APIEnvironment(
                            title: APIEnvironmentEntity.sandbox3.rawValue,
                            environment: .sandbox3
                        )
                    ]
                ),
            toggleLogs:
                LogTogglingAlert(
                    enableTitle: Strings.Localizable.enableDebugModeTitle,
                    enableMessage: Strings.Localizable.enableDebugModeMessage,
                    disableTitle: Strings.Localizable.disableDebugModeTitle,
                    disableMessage: Strings.Localizable.disableDebugModeMessage,
                    mainActionTitle: Strings.Localizable.ok,
                    cancelActionTitle: Strings.Localizable.cancel
                )
        )
    }
}

extension SettingSectionViewModel {
    init(@SettingSectionBuilder _ makeCells: () -> [SettingCellViewModel]) {
        self.init(cellViewModels: makeCells())
    }
}
