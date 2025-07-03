import Accounts
import ChatRepo
import LogRepo
import MEGAAnalytics
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAuthentication
import MEGAAuthenticationOrchestration
import MEGADomain
import MEGAInfrastructure
import MEGAPermissions
import MEGAPreference
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

extension AppDelegate {
    @objc func injectSDKRepoDependencies() {
        MEGASDKRepo.DependencyInjection.sharedSdk = .shared
    }
    
    @objc func injectAuthenticationDependencies() {
        guard isLoginRegisterAndOnboardingRevampFeatureEnabled else { return }

        MEGAAuthentication.DependencyInjection.sharedSdk = .shared
        MEGAAuthentication.DependencyInjection.keychainServiceName = "MEGA"
        MEGAAuthentication.DependencyInjection.keychainAccount = "sessionV3"
        MEGAAuthentication.DependencyInjection.snackbarDisplayer = VisibleViewControllerSnackBarDisplayer()
        
        MEGAAuthentication.DependencyInjection.loginUseCase = makeLoginUseCase()
        
        MEGAAuthentication.DependencyInjection.createAccountUseCase = KeychainStoringCreateAccountUseCase(
            createAccountUseCase: CreateAccountUseCase(
                repository: CreateAccountRepository(
                    sdk: MEGAAuthentication.DependencyInjection.sharedSdk)),
            keychainRepository: MEGAAuthentication.DependencyInjection.keychainRepository)
        
        MEGAAuthentication.DependencyInjection.analyticsTracker = AnalyticsTrackerAdapter()
        
        MEGAAuthentication.DependencyInjection.accountConfirmationUseCase = makeAccountConfirmationUseCase()
        
        MEGAAuthentication.DependencyInjection.configureAuthEnvironmentUseCase = makeConfigureAuthEnvironmentUseCase()
    }

    @objc func injectInfrastructureDependencies() {
        MEGAInfrastructure.DependencyInjection.sharedSdk = .shared
    }

    @objc func makeOnboardingViewController() -> UIViewController {
        if isLoginRegisterAndOnboardingRevampFeatureEnabled {
            OnboardingUSPViewController()
        } else {
            OnboardingViewController.instantiateOnboarding(with: .default)
        }
    }
    
    @objc func isRootViewNewOnboarding() -> Bool {
        window.rootViewController is OnboardingUSPViewController
    }
    
    @objc func handlePostLoginSetup(isFirstLogin: Bool) {
        setAccountFirstLogin(isFirstLogin)
        postLoginNotification()
        initProviderDelegate()
        registerForNotifications()
        
        MEGASdk.shared.fetchNodes()
        
        QuickAccessWidgetManager.reloadAllWidgetsContent()
        
        MEGAPurchase.sharedInstance().requestPricing()
        MEGAPurchase.sharedInstance().checkForCancellation()
    }
    
    @objc func isOnboardingViewControllerAlreadyShown() -> Bool {
        if  isLoginRegisterAndOnboardingRevampFeatureEnabled {
            isRootViewNewOnboarding()
        } else {
            window.rootViewController is OnboardingViewController
        }
    }

    @objc var isLoginRegisterAndOnboardingRevampFeatureEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .loginRegisterAndOnboardingRevamp)
    }
    
    @objc func showConfirmEmailView() {
        guard let name = SAMKeychain.password(forService: "MEGA", account: "name"),
              let email = SAMKeychain.password(forService: "MEGA", account: "email"),
              let password = SAMKeychain.password(forService: "MEGA", account: "password") else {
            MEGALogError("Information from sessionId was not stored by MEGACreateAccountRequestDelegate")
            return
        }
        if let onboardingViewController = window.rootViewController as? OnboardingUSPViewController {
            onboardingViewController.presentConfirmEmail(
                information: .init(
                    name: name,
                    email: email,
                    password: password))
        } else {
            let checkEmailAndFollowTheLinkVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "CheckEmailAndFollowTheLinkViewControllerID")
            checkEmailAndFollowTheLinkVC.modalPresentationStyle = .fullScreen
            
            UIApplication.mnz_presentingViewController().present(checkEmailAndFollowTheLinkVC, animated: true)
        }
    }
    
    private func makeLoginUseCase() -> some LoginUseCaseProtocol {
        let loginUseCase = LoginUseCase(
            fetchNodesEnabled: false,
            shouldIncludeFastLoginTimeout: false,
            updateDuplicateSession: true,
            loginAPIRepository: MEGAAuthentication.DependencyInjection.loginAPIRepository,
            loginStoreRepository: MEGAAuthentication.DependencyInjection.loginStoreRepository)
        
        let postLoginActionsUseCase = LoginWithPostActionsUseCase(
            loginUseCase: loginUseCase,
            postLoginActions: [AppDelegatePostLoginAction(appDelegate: self)])
        
        return LoginWithPreLoginActionsUseCase(
            loginUseCase: postLoginActionsUseCase,
            preLoginActions: [
                UpdateChatSDKPreLoginAction(),
                EnsureAudioPlayerStoppedPreLoginAction(
                    streamingInfoUseCase: StreamingInfoUseCase())])
    }
    
    private func makeAccountConfirmationUseCase() -> some AccountConfirmationUseCaseProtocol {
        ClearKeychainAccountConfirmationUseCase(
            accountConfirmationUseCase: AccountConfirmationUseCase(
                repository: AccountConfirmationRepository(
                    sdk: MEGAAuthentication.DependencyInjection.sharedSdk)),
            keychainRepository: MEGAAuthentication.DependencyInjection.keychainRepository)
    }
    
    private func makeConfigureAuthEnvironmentUseCase() -> some ConfigureAuthEnvironmentUseCaseProtocol {
        let preferenceUseCase = PreferenceUseCase(repository: PreferenceRepository.newRepo)
        return ConfigureAuthEnvironmentUseCase(
            logMetadataEntity: makeLogMetaDataEntity(),
            preferenceUseCase: preferenceUseCase,
            apiEnvironmentUseCase: APIEnvironmentUseCase(
                apiEnvironmentRepository: APIEnvironmentRepository.newRepo,
                chatURLRepository: ChatURLRepository.newRepo),
            manageLogsUseCase: ManageLogsUseCase(
                repository: LogSettingRepository.newRepo,
                preferenceUseCase: preferenceUseCase)
        )
    }
    
    private func makeLogMetaDataEntity() -> LogMetadataEntity {
        let appMetaData = AppMetaDataFactory(bundle: .main).make()
        let deviceMetaData = DeviceMetaDataFactory(
            bundle: .main,
            locale: NSLocale.current as NSLocale).make()
        
        return LogMetadataEntity(
            suiteName: MEGAGroupIdentifier,
            key: PreferenceKeyEntity.logging.rawValue,
            version: appMetaData.currentAppVersion,
            systemVersion: UIDevice.current.systemVersion,
            language: deviceMetaData.language,
            deviceName: deviceMetaData.deviceName,
            timezoneName: TimeZone.current.identifier,
            extensionLogsFolder: MEGAExtensionLogsFolder)
    }
}

private struct UpdateChatSDKPreLoginAction: PreLoginAction {
    private let chatSdk: MEGAChatSdk
    
    init(chatSdk: MEGAChatSdk = .shared) {
        self.chatSdk = chatSdk
    }
    
    func handle() async throws {
        guard chatSdk.initState() != .waitingNewSession else { return }
        guard chatSdk.initKarere(withSid: nil) != .waitingNewSession else { return }
        
        MEGALogError("Init Karere without session must return waiting for a new session")
        chatSdk.logout()
    }
}

private struct EnsureAudioPlayerStoppedPreLoginAction: PreLoginAction {
    private let streamingInfoUseCase: any StreamingInfoUseCaseProtocol
    
    init(streamingInfoUseCase: some StreamingInfoUseCaseProtocol) {
        self.streamingInfoUseCase = streamingInfoUseCase
    }
    
    func handle() async throws {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        let streamingInfoUseCase = StreamingInfoUseCase()
        streamingInfoUseCase.stopServer()
    }
}

private struct AppDelegatePostLoginAction: PostLoginAction {
    let appDelegate: AppDelegate
    
    @MainActor
    func handlePostLogin() async throws {
        appDelegate.handlePostLoginSetup(isFirstLogin: true)
    }
}

private struct AnalyticsTrackerAdapter: MEGAAnalyticsTrackerProtocol {
    private let tracker: any MEGAAppPresentation.AnalyticsTracking

    init(tracker: some MEGAAppPresentation.AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }

    func trackAnalyticsEvent(with event: some MEGAAnalytics.AnalyticsEventEntityProtocol) {
        guard let identifer = event.identifier else { return }
        tracker.trackAnalyticsEvent(with: identifer)
    }
}

private struct VisibleViewControllerSnackBarDisplayer: SnackbarDisplaying {
    func display(_ snackbar: SnackbarEntity) {
        Task { @MainActor in
            UIApplication.mnz_visibleViewController()
                .showSnackBar(snackBar: snackbar.toSnackbar())
        }
    }
}

private extension SnackbarEntity {
    func toSnackbar() -> SnackBar {
        let action: SnackBar.Action? = if let actionLabel,
                                          let action {
            .init(title: actionLabel, handler: action)
        } else {
            nil
        }
        return .init(
            message: text,
            action: action)
    }
}
