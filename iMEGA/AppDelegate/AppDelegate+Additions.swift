import Chat
import ChatRepo
import Combine
import FirebaseCrashlytics
import Foundation
import Intents
import LogRepo
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo
import PushKit
import SafariServices

extension AppDelegate {
    @objc func showEnableTwoFactorAuthenticationIfNeeded() {
        if UserDefaults.standard.bool(forKey: "twoFactorAuthenticationAlreadySuggested") {
            return
        }

        MEGASdk.shared.multiFactorAuthCheck(withEmail: MEGASdk.currentUserEmail ?? "", delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                if request.flag {
                    return // Two Factor Authentication Enabled
                }
            case .failure:
                break
            }
            if UIApplication.mnz_visibleViewController() is AddPhoneNumberViewController ||
                UIApplication.mnz_visibleViewController() is CustomModalAlertViewController ||
                UIApplication.mnz_visibleViewController() is AccountExpiredViewController ||
                (MEGASdk.shared.isAccountType(.business) &&
                 MEGASdk.shared.businessStatus != .active) {
                return
            }
            
            if LTHPasscodeViewController.doesPasscodeExist() && LTHPasscodeViewController.sharedUser().isLockscreenPresent() {
                return
            }
            
            let enable2FACustomModalAlert = CustomModalAlertViewController()
            enable2FACustomModalAlert.configureForTwoFactorAuthentication(requestedByUser: false)

            UIApplication.mnz_presentingViewController().present(enable2FACustomModalAlert, animated: true, completion: nil)
            
            UserDefaults.standard.set(true, forKey: "twoFactorAuthenticationAlreadySuggested")
        })
    }
    
    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    // we do not want to present two CustomModals on top of each other, also
    // do not present modal on top of Account expired
    var shouldPresentModal: Bool {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        return !(
            visibleViewController is CustomModalAlertViewController ||
            visibleViewController is AccountExpiredViewController
        )
    }
    
    @objc func showTurnOnNotificationsIfNeeded() {
        
        guard shouldPresentModal else { return }
        
        permissionHandler.notificationsPermissionsStatusDenied { denied in
            if denied {
                TurnOnNotificationsViewRouter(presenter: UIApplication.mnz_presentingViewController()).start()
            }
        }
    }
    
    @objc func showCookieDialogIfNeeded() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
        
        if cookieSettingsUseCase.cookieBannerEnabled() {
            Task { @MainActor in
                do {
                    // Cookie settings already set
                    let bitmap = try await cookieSettingsUseCase.cookieSettings()
                    
                    // Check if new ads cookie is set
                    guard await isExternalAdsActive() else { return }
                    
                    let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
                    guard !cookiesBitmap.contains(.adsCheckCookie) else { return }
                    
                    // Ads cookie not yet set. Show manage cookies with ads policy.
                    showCookieDialog(type: .adsCookiePolicy)
                    
                } catch {
                    guard let error = error as? CookieSettingsErrorEntity else { return }
                    switch error {
                    case .generic, .invalidBitmap: break
                        
                    case .bitmapNotSet:
                        let isExternalAdsActive = await isExternalAdsActive()
                        showCookieDialog(type: isExternalAdsActive ? .adsCookiePolicy : .noAdsCookiePolicy)
                    }
                }
            }
        }
    }
    
    private func isExternalAdsActive() async -> Bool {
        let abTestProvider = DIContainer.abTestProvider
        let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
        let isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
        return isAdsEnabled && isExternalAdsEnabled
    }
    
    func openCallUIForInProgressCall(presenter: UIViewController, chatRoom: ChatRoomEntity, isSpeakerEnabled: Bool) {
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatRoom.chatId) else { return }
        MeetingContainerRouter(presenter: presenter,
                               chatRoom: chatRoom,
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
        
    private func showCookieDialog(type: CustomModalAlertViewController.CookieDialogType) {
        guard shouldPresentModal else { return }

        Task {
            let cookiePolicyURL = await cookiePolicyURL(isExternalAds: type == .adsCookiePolicy)
            
            let cookieDialogView = CustomModalAlertViewController()
            cookieDialogView.configureForCookieDialog(type: type, cookiePolicyURLString: cookiePolicyURL)
            UIApplication.mnz_presentingViewController().present(cookieDialogView, animated: true, completion: nil)
        }
    }
    
    private func cookiePolicyURL(isExternalAds: Bool) async -> String {
        let invalidURLString = "invalid://urlLink"
        guard let cookiePolicyURL = URL(string: "https://mega.nz/cookie") else { return invalidURLString }
        
        // If external Ads is not active, cookie policy will not require session
        guard isExternalAds else { return cookiePolicyURL.absoluteString }
        
        // If external Ads is active, cookie policy will be directed to link with session
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        do {
            let url = try await accountUseCase.sessionTransferURL(path: cookiePolicyURL.lastPathComponent)
            return url.absoluteString
        } catch {
            return invalidURLString
        }
    }

    @objc func showLaunchTabDialogIfNeeded() {
        
        if TabManager.isLaunchTabSelected() || TabManager.isLaunchTabDialogAlreadySuggested() {
            return
        }
        
        if let firstLoginDate = UserDefaults.standard.value(forKey: MEGAFirstLoginDate) {
            guard let days = Calendar.current.dateComponents([.day], from: firstLoginDate as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }
        
        showLaunchTabDialog()
    }
    
    private func showLaunchTabDialog() {
        guard shouldPresentModal else { return }
        
        let launchTabDialogCustomModalAlert = CustomModalAlertViewController()
        launchTabDialogCustomModalAlert.configureForChangeLaunchTab()

        UIApplication.mnz_presentingViewController().present(launchTabDialogCustomModalAlert, animated: true) {
            TabManager.setLaunchTabDialogAlreadyAsSuggested()
        }
    }
    
    @objc func updateContactsNickname() {
        MEGASdk.shared.getUserAttributeType(.alias, delegate: RequestDelegate { (result) in
            if case let .success(request) = result {
                guard let stringDictionary = request.megaStringDictionary else { return }
                
                let names = stringDictionary.compactMap { (key, value) -> (HandleEntity, String)? in
                    guard let nickname = value.base64URLDecoded else { return nil }
                    return (MEGASdk.handle(forBase64UserHandle: key), nickname)
                }
                
                MEGAStore.shareInstance().updateUserNicknames(by: names)
                
                OperationQueue.main.addOperation {
                    NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded), object: nil)
                }
            }
        })
    }

    @objc func handleAccountBlockedEvent(_ event: MEGAEvent) {
        guard let suspensionType = AccountSuspensionType(rawValue: event.number) else { return }

        if suspensionType == .smsVerification && MEGASdk.shared.smsAllowedState() != .notAllowed {
            if UIApplication.mnz_presentingViewController() is SMSNavigationViewController {
                return
            }

            SMSVerificationViewRouter(verificationType: .unblockAccount, presenter: UIApplication.mnz_presentingViewController()).start()
        } else if suspensionType == .emailVerification {
            if UIApplication.mnz_visibleViewController() is VerifyEmailViewController || UIApplication.mnz_visibleViewController() is SFSafariViewController {
                return
            }

            let verifyEmailVC = UIStoryboard(name: "VerifyEmail", bundle: nil).instantiateViewController(withIdentifier: "VerifyEmailViewControllerID")
            UIApplication.mnz_presentingViewController().present(verifyEmailVC, animated: true, completion: nil)
        } else {
            var message: String
            
            switch suspensionType {
            case .businessDisabled:
                message = Strings.Localizable.YourAccountHasBeenDisabledByYourAdministrator.pleaseContactYourBusinessAccountAdministratorForFurtherDetails
            case .businessRemoved:
                message = Strings.Localizable.YourAccountHasBeenRemovedByYourAdministrator.pleaseContactYourBusinessAccountAdministratorForFurtherDetails
            case .copyright:
                message = Strings.Localizable.Account.Suspension.Message.copyright
            case .nonCopyright:
                message = Strings.Localizable.Account.Suspension.Message.nonCopyright
            default:
                return
            }
            
            let alert = UIAlertController(title: Strings.Localizable.error, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel) { _ in
                MEGASdk.shared.logout()
            })
            UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
        }
    }

    @objc func registerForNotifications() {
        permissionHandler.shouldAskForNotificationsPermissions { shouldAsk in
            // this code here seems to work on assumption that,
            // we were granted authorization in the past
            // and we can progress with registering for remote notifications
            if !shouldAsk {
                self.permissionHandler.notificationsPermission(with: { granted in
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                })
            }
        }
    }
    
    @objc func handleFatalError(event: MEGAEvent) {
        let error = NSError.init(
            domain: "nz.mega.eventFatalError",
            code: event.number,
            userInfo: [NSLocalizedDescriptionKey: "Fatal error event received from SDK: \(event.eventString ?? "")"]
        )
        Crashlytics.crashlytics().record(error: error)
        
        if event.number == 3 {
            NotificationCenter.default.post(name: NSNotification.Name.MEGASQLiteDiskFull, object: nil)
        }
    }
}

// MARK: - Config Cookie Settings

extension AppDelegate {
    @objc func configAppWithNewCookieSettings() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
        
        Task {
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            let isPerformanceAndAnalyticsEnabled = CookiesBitmap(rawValue: bitmap).contains(.analytics)
            cookieSettingsUseCase.setCrashlyticsEnabled(isPerformanceAndAnalyticsEnabled)
        }
    }
}

// MARK: SQLite disk full
extension AppDelegate {
    @objc func didReceiveSQLiteDiskFullNotification() {
        DispatchQueue.main.async {
            guard self.blockingWindow == nil else { return }
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.windowLevel = .alert + 1
            DiskFullBlockingViewRouter(window: window).start()
            self.blockingWindow = window
        }
    }
}

// MARK: - MEGAChatSdk onDBError
extension AppDelegate {
    @objc func handleChatDBError(error: MEGAChatDBError, message: String) {
        let recordError = NSError.init(
            domain: "nz.mega.chatDBError",
            code: error.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "DB error received from chat"]
        )
        Crashlytics.crashlytics().record(error: recordError)
        
        switch error {
        case .full:
            NotificationCenter.default.post(name: NSNotification.Name.MEGASQLiteDiskFull, object: nil, userInfo: nil)
            
        default:
            CrashlyticsLogger.log("MEGAChatSDK onDBError occurred. Error \(error) with message \(message)")
            MEGAChatSdk.shared.deleteMegaChatApi()
            MEGASdk.shared.deleteMegaApi()
            MEGASdk.sharedFolderLink.deleteMegaApi()
            exit(0)
        }
    }
}

// MARK: - Register for background refresh
extension AppDelegate {
    @objc func registerCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.register()
    }
}

// MARK: - Show launch view controller
extension AppDelegate {
    @objc func showLaunchViewController() {
        let launchViewContrller = UIStoryboard(name: "Launch", bundle: nil).instantiateViewController(identifier: "LaunchViewControllerID")
        UIView.transition(with: window, duration: 0.5,
                          options: [.transitionCrossDissolve, .allowAnimatedContent]) { [weak self] in
            self?.window.rootViewController = launchViewContrller
        }
    }
}

// MARK: - Logger
extension AppDelegate {
    @objc func enableLogsIfNeeded() {
        let logUseCase = LogUseCase(preferenceUseCase: PreferenceUseCase.default, appEnvironment: AppEnvironmentUseCase.shared)
        if logUseCase.shouldEnableLogs() {
            enableLogs()
        }
    }
    
    private func enableLogs() {
        MEGASdk.setLogLevel(.max)
        MEGAChatSdk.setLogLevel(.max)
        MEGASdk.shared.add(Logger.shared())
        MEGAChatSdk.setLogObject(Logger.shared())
        setupChatLogging()
    }
    
    private func setupChatLogging() {
        Chat.logFatal = { MEGALogFatal($0, $1, $2) }
        Chat.logError = { MEGALogError($0, $1, $2) }
        Chat.logWarning = { MEGALogWarning($0, $1, $2) }
        Chat.logInfo = { MEGALogInfo($0, $1, $2) }
        Chat.logDebug = { MEGALogDebug($0, $1, $2) }
        Chat.logMax = { MEGALogMax($0, $1, $2) }
    }
    
    @objc func removeSDKLoggerWhenInitChatIfNeeded() {
        let logUseCase = LogUseCase(preferenceUseCase: PreferenceUseCase.default, appEnvironment: AppEnvironmentUseCase.shared)

        if logUseCase.shouldEnableLogs() {
            MEGASdk.shared.remove(Logger.shared())
        }
    }
}

// MARK: - Generic App push notifications
 extension AppDelegate {
    @objc func handleReceivedRemoteNotification(userInfo: [String: Any]) {
        guard let notificationType = userInfo["megatype"] as? Int else { return }
        
        if case MEGANotificationType.generic.rawValue = notificationType {
            DIContainer.tracker.trackAnalyticsEvent(with: GenericAppPushNotificationReceivedEvent())
        }
    }
    
    @objc func handleGenericAppPushNotificationTap(userInfo: [String: Any]?) {
        DIContainer.tracker.trackAnalyticsEvent(with: GenericAppPushNotificationTappedEvent())
        
        guard let megaData = userInfo?["megadata"] as? [String: Any],
              let urlString = megaData["generic_href"] as? String,
              let trimmedURL = urlString.trim,
              let url = NSURL(string: trimmedURL) else {
            MEGALogError("[Notification] URL NOT opened. Can't parse notification link.")
            SVProgressHUD.showError(withStatus: Strings.Localizable.linkNotValid)
            return
        }
        
        switch url.mnz_type() {
        case .default: 
            // Added delay to show the mega app for a moment and not flash the in-app browser to the user
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 500_000_000)
                url.mnz_presentSafariViewController()
            }
        default:
            guard let deepLinkURL = URL(string: urlString),
                  UIApplication.shared.canOpenURL(deepLinkURL) else {
                return
            }
            UIApplication.shared.open(deepLinkURL)
        }
    }
 }

// MARK: - Actionable notification for Scheduled meetings

extension AppDelegate {
    
    @objc(isScheduleMeetingNotification:)
    func isScheduleMeeting(notification: UNNotification) -> Bool {
        ScheduleMeetingPushNotifications.isScheduleMeeting(notification: notification)
    }
    
    @objc func hasTappedOnJoinAction(response: UNNotificationResponse) -> Bool {
        ScheduleMeetingPushNotifications.hasTappedOnJoinAction(forResponse: response)
    }
    
    @MainActor
    @objc func openScheduleMeeting(forChatId chatId: ChatIdEntity, retry: Bool = true) {
        DIContainer.tracker.trackAnalyticsEvent(with: ScheduledMeetingReminderNotificationMessageButtonEvent())

        guard MEGAChatSdk.shared.chatRoom(forChatId: chatId) != nil else {
            guard retry else { return }
            
            Task {
                do {
                    try await waitUntilChatStatusComesOnline(forChatId: chatId)
                    openScheduleMeeting(forChatId: chatId, retry: false)
                } catch {
                    MEGALogError("Unable to wait until the status is online error \(error)")
                }
            }
            
            return
        }
        
        guard let mainTabBarController = mainTBC else {
            MEGALogDebug("Unable to find the main tabbar controller")
            self.openChatLater = NSNumber(value: chatId)
            return
        }
        
        mainTabBarController.openChatRoom(chatId: chatId)
    }
    
    @MainActor
    @objc func joinScheduleMeeting(forChatId chatId: ChatIdEntity, retry: Bool = true) {
        DIContainer.tracker.trackAnalyticsEvent(with: ScheduledMeetingReminderNotificationJoinButtonEvent())
        
        guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatId)?.toChatRoomEntity() else {
            return
        }
        
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatId), call.status == .inProgress else {
            Task {
                do {
                    try await openWaitingRoomOrStartCallWithNoRinging(forChatRoom: chatRoom)
                } catch {
                    MEGALogDebug("Unable to start call for chat id \(chatId) with error \(error)")
                }
            }
            
            return
        }
        
        openCallUIForInProgressCall(presenter: UIApplication.mnz_presentingViewController(), chatRoom: chatRoom, isSpeakerEnabled: AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker))
    }
    
    @objc func registerCustomActionsForStartScheduledMeetingNotification() {
        ScheduleMeetingPushNotifications.registerCustomActions()
    }
    
    @objc func toggleFeatureFlags() {
        FeatureFlagProvider.disableFeatureFlags = false
    }
    
    @MainActor
    private func openWaitingRoomOrStartCallWithNoRinging(forChatRoom chatRoom: ChatRoomEntity) async throws {
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)

        if let scheduleMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId).first,
           shouldOpenWaitingRoom(for: chatRoom) {
            openWaitingRoom(for: scheduleMeeting)
        } else {
            startCallWithNoRinging(inChatRoom: chatRoom)
        }
    }
    
    private func startCallWithNoRinging(inChatRoom chatRoom: ChatRoomEntity) {
        let callManager = CallKitCallManager.shared
        let callUseCase = CallUseCase(repository: CallRepository.newRepo)
        if callUseCase.call(for: chatRoom.chatId) != nil {
            if let incomingCallUUID = callManager.callUUID(forChatRoom: chatRoom) {
                callManager.answerCall(in: chatRoom, withUUID: incomingCallUUID)
            } else {
                callManager.startCall(
                    with: CallActionSync(
                        chatRoom: chatRoom,
                        notRinging: true,
                        isJoiningActiveCall: true
                    )
                )
            }
        } else {
            callManager.startCall(
                with: CallActionSync.startCallNoRinging(in: chatRoom)
            )
        }
    }
    
    private func shouldOpenWaitingRoom(for chatRoom: ChatRoomEntity) -> Bool {
        let isModerator = chatRoom.ownPrivilege == .moderator
        return !isModerator && chatRoom.isWaitingRoomEnabled
    }
    
    @MainActor
    private func openWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity) {
        WaitingRoomViewRouter(presenter: UIApplication.mnz_presentingViewController(), scheduledMeeting: scheduledMeeting).start()
    }
    
    private func waitUntilChatStatusComesOnline(forChatId chatId: HandleEntity) async throws {
        let chatConnectionProvider = ChatConnectionStateUpdateProvider(sdk: .sharedChatSdk)
  
        _ = await chatConnectionProvider
            .updates
            .first { @Sendable in $0 == chatId && $1 == .online }
    }
    
    private var permissionAlertRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }

    // MARK: - Show upgrade Screen

    @objc func showUpgradeAccount() {
        guard MEGAPurchase.sharedInstance().products != nil && MEGAPurchase.sharedInstance().products.isNotEmpty else {
            MEGALogDebug("[Upgrade Account] In app purchase products not loaded")
            MEGAPurchase.sharedInstance().pricingsDelegateMutableArray.add(self)
            self.loadProductsAndShowAccountUpgradeScreen = true
            return
        }

        guard MEGASdk.shared.mnz_accountDetails != nil else {
            MEGALogDebug("[Upgrade Account] Account details are empty")
            self.showAccountUpgradeScreen = true
            return
        }

        UpgradeAccountRouter().presentUpgradeTVC()
    }

    // MARK: - Account details
    @objc func refreshAccountDetails() {
        Task {
            do {
                let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
                _ = try await accountUseCase.refreshCurrentAccountDetails()
            } catch {
                MEGALogError("Error loading account details. Error: \(error)")
            }
        }
    }
    
    // MARK: - Transfer Quota Dialog
    @objc func handleDownloadQuotaError(_ error: MEGAError, transfer: MEGATransfer) {
        guard error.value != 0 else { return }
        
        var alertDisplayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode
        switch error.type {
        case .apiEgoingOverquota:
            alertDisplayMode = .limitedDownload
        case .apiEOverQuota:
            alertDisplayMode = transfer.isStreamingTransfer ? .streamingExceeded : .downloadExceeded
        default: return
        }
        
        // Get latest account details if user is logged in and current account details is nil
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        if accountUseCase.isLoggedIn(), accountUseCase.currentAccountDetails == nil {
            Task {
                do {
                    _ = try await accountUseCase.refreshCurrentAccountDetails()
                    showTransferQuotaModalAlert(mode: alertDisplayMode)
                } catch {
                    MEGALogError("[Transfer Quota Dialog] No user account details with error \(error)")
                }
            }
        } else {
            showTransferQuotaModalAlert(mode: alertDisplayMode)
        }
    }
    
    private func showTransferQuotaModalAlert(mode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode) {
        CustomModalAlertRouter(
            .transferDownloadQuotaError,
            presenter: UIApplication.mnz_presentingViewController(),
            transferQuotaDisplayMode: mode
        ).start()
        
        NotificationCenter.default.post(name: .MEGATransferOverQuota, object: self)
    }
    
    @objc func showChooseAccountPlanTypeView() {
        UpgradeAccountRouter().presentChooseAccountType()
    }
    
    // MARK: - Promoted plan
    @objc func listenToStorePaymentTransactions() {
        SKPaymentQueue.default().add(MEGAPurchase.sharedInstance())
    }
    
    // MARK: - ChatUploader
    @objc func chatUploaderSetup() {
        ChatUploader.sharedInstance.setup()
    }
    
    // MARK: - Shared links
    @objc func showSharedLinkForNoLoggedInUser(_ url: URL) {
        Task {
            // Try to get miscellanous flags before showing the shared link
            do {
                let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
                try await accountUseCase.getMiscFlags()
                showLink(url)
            } catch {
                MEGALogError("[Misc Flag]Error getting miscellanous flags.")
                showLink(url)
            }
        }
    }
}

// MARK: - Quick Action related
extension AppDelegate {

    @objc static func matchQuickAction(_ inputType: String, with type: String) -> Bool {
        let regexPattern = "^mega\\.ios(?:\\.[a-zA-Z]+)?\\.\(type)$"
        
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return false
        }
        
        let range = NSRange(location: 0, length: inputType.utf16.count)
        return regex.firstMatch(in: inputType, options: [], range: range) != nil
    }
}

// MARK: - Handlers for app exit event
extension AppDelegate {
    /// Perform custom clean up actions upon app termination by exit()
    @objc func registerAppExitHandlers() {
        AppExitHandlerManager().registerExitHandler {
            MEGAChatSdk.shared.deleteMegaChatApi()
            MEGASdk.shared.deleteMegaApi()
        }
    }
}

// MARK: - Legacy CallKit management: provider delegate and controller, VoIP push
extension AppDelegate {
    @objc func initProviderDelegate() {
        guard callsCoordinator == nil else { return }
        let callsCoordinator = CallsCoordinatorFactory().makeCallsCoordinator(
            scheduler: .main,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            sessionUpdateUseCase: SessionUpdateUseCase(repository: SessionUpdateRepository.newRepo),
            noUserJoinedUseCase: MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            callManager: CallKitCallManager.shared,
            passcodeManager: PasscodeManager(),
            uuidFactory: { UUID() },
            callUpdateFactory: .defaultFactory
        )
        self.callsCoordinator = callsCoordinator
        voIPPushDelegate = VoIPPushDelegate(
            callCoordinator: callsCoordinator,
            voIpTokenUseCase: VoIPTokenUseCase(repo: VoIPTokenRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            logger: {
                CrashlyticsLogger.log(category: .calls, $0)
            }
        )
    }
    
    @objc func startCall(fromIntent intent: INStartCallIntent) {
        mainTBC?.mainTabBarViewModel.dispatch(.startCallIntent(intent))
    }
}
