import Combine
import Foundation
import MEGAData
import MEGADomain
import MEGAPresentation
import MEGAPermissions
import SafariServices

extension AppDelegate {
    @objc func showEnableTwoFactorAuthenticationIfNeeded() {
        if UserDefaults.standard.bool(forKey: "twoFactorAuthenticationAlreadySuggested") {
            return
        }

        MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: MEGASdk.currentUserEmail ?? "", delegate: MEGAGenericRequestDelegate.init(completion: { (request, _) in
            if request.flag {
                return // Two Factor Authentication Enabled
            }

            if UIApplication.mnz_visibleViewController() is AddPhoneNumberViewController ||
                UIApplication.mnz_visibleViewController() is CustomModalAlertViewController ||
                UIApplication.mnz_visibleViewController() is AccountExpiredViewController ||
                (MEGASdkManager.sharedMEGASdk().isAccountType(.business) &&
                 MEGASdkManager.sharedMEGASdk().businessStatus != .active) {
                return
            }
            
            if LTHPasscodeViewController.doesPasscodeExist() && LTHPasscodeViewController.sharedUser().isLockscreenPresent() {
                return
            }
            
            let enable2FACustomModalAlert = CustomModalAlertViewController()
            enable2FACustomModalAlert.configureForTwoFactorAuthentication(requestedByUser: false)

            UIApplication.mnz_presentingViewController().present(enable2FACustomModalAlert, animated: true, completion: nil)
            
            UserDefaults.standard.set(true, forKey: "twoFactorAuthenticationAlreadySuggested")
        }))
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
            cookieSettingsUseCase.cookieSettings { [weak self] in
                switch $0 {
                case .success: break // Cookie settings already set
                    
                case .failure(let error):
                    switch error {
                    case .generic, .invalidBitmap: break
                        
                    case .bitmapNotSet:
                        self?.showCookieDialog()
                    }
                }
            }
        }
    }
    
    @objc func performCall(presenter: UIViewController, chatRoom: MEGAChatRoom, isSpeakerEnabled: Bool) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        MeetingContainerRouter(presenter: presenter,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
        
    private func showCookieDialog() {
        
        guard shouldPresentModal else { return }
        
        let cookieDialogCustomModalAlert = CustomModalAlertViewController()
        cookieDialogCustomModalAlert.configureForCookieDialog()

        UIApplication.mnz_presentingViewController().present(cookieDialogCustomModalAlert, animated: true, completion: nil)
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
        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: RequestDelegate { (result) in
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

        if suspensionType == .smsVerification && MEGASdkManager.sharedMEGASdk().smsAllowedState() != .notAllowed {
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
                MEGASdkManager.sharedMEGASdk().logout()
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
}

// MARK: - Config Cookie Settings

extension AppDelegate {
    @objc func configAppWithNewCookieSettings() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
        cookieSettingsUseCase.cookieSettings {
            switch $0 {
            case .success(let bitmap):
                let isPerformanceAndAnalyticsEnabled = CookiesBitmap(rawValue: bitmap).contains(.analytics)
                cookieSettingsUseCase.setCrashlyticsEnabled(isPerformanceAndAnalyticsEnabled)

            case .failure: break
            }
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
        switch error {
        case .full:
            NotificationCenter.default.post(name: NSNotification.Name.MEGASQLiteDiskFull, object: nil, userInfo: nil)
            
        default:
            CrashlyticsLogger.log("MEGAChatSDK onDBError occurred. Error \(error) with message \(message)")
            MEGASdkManager.deleteSharedSdks()
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
        MEGASdkManager.sharedMEGASdk().add(Logger.shared())
        MEGAChatSdk.setLogObject(Logger.shared())
    }
    
    @objc func removeSDKLoggerWhenInitChatIfNeeded() {
        let logUseCase = LogUseCase(preferenceUseCase: PreferenceUseCase.default, appEnvironment: AppEnvironmentUseCase.shared)

        if logUseCase.shouldEnableLogs() {
            MEGASdkManager.sharedMEGASdk().remove(Logger.shared())
        }
    }
}

// MARK: - Shared Secure fingerprint
extension AppDelegate {
    @objc func configSharedSecureFingerprintFlag() {
        let secureFlagManager = SharedSecureFingerprintManager()
        let isSecure = secureFlagManager.secureFingerprintVerification
        secureFlagManager.setSecureFingerprintFlag(isSecure)
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
        guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatId) else {
            guard retry else { return }
            
            Task {
                do {
                    try await waitUntilChatStatusComesOnline(forChatId: chatId)
                    joinScheduleMeeting(forChatId: chatId, retry: false)
                } catch {
                    MEGALogDebug("Unable to wait until the status is online error \(error)")
                }
            }
            
            return
        }
        
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatId), call.status == .inProgress else {
            if MEGAChatSdk.shared.chatConnectionState(chatId) == .online {
                Task {
                    do {
                        try await startCallWithNoRinging(forChatRoom: chatRoom)
                    } catch {
                        MEGALogDebug("Unable to start call for chat id \(chatId) with error \(error)")
                    }
                }
            } else {
                Task {
                    do {
                        try await waitUntilChatStatusComesOnline(forChatId: chatId)
                        try await startCallWithNoRinging(forChatRoom: chatRoom)
                    } catch {
                        MEGALogDebug("Unable to wait until the chat status is online and start call for chat id \(chatId) with error \(error)")
                    }
                }
            }
            
            return
        }
        
        performCall(presenter: UIApplication.mnz_presentingViewController(), chatRoom: chatRoom, isSpeakerEnabled: AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker))
    }
    
    @objc func registerCustomActionsForStartScheduledMeetingNotification() {
        ScheduleMeetingPushNotifications.registerCustomActions()
    }
    
    @objc func toggleFeatureFlags() {
        #if QA_CONFIG
            FeatureFlagProvider.disableFeatureFlags = false
        #endif
    }
        
    private func startCallWithNoRinging(forChatRoom chatRoom: MEGAChatRoom) async throws {
        let audioSessionUC = AudioSessionUseCase(audioSessionRepository: AudioSessionRepository(audioSession: AVAudioSession(), callActionManager: CallActionManager.shared))
        audioSessionUC.configureCallAudioSession()
        audioSessionUC.enableLoudSpeaker()
        
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGASdkManager.sharedMEGAChatSdk()))
        let callUseCase = CallUseCase(repository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared))

        if let scheduleMeeting = scheduledMeetingUseCase.scheduledMeetingsByChat(chatId: chatRoom.chatId).first {
            let callEntity = try await callUseCase.startCallNoRinging(for: scheduleMeeting, enableVideo: false, enableAudio: true)
            join(call: callEntity, chatRoom: chatRoom.toChatRoomEntity())
        } else {
            let callEntity = try await callUseCase.startCall(for: chatRoom.chatId, enableVideo: false, enableAudio: true)
            join(call: callEntity, chatRoom: chatRoom.toChatRoomEntity())
        }
    }
    
    @MainActor
    private func join(call: CallEntity, chatRoom: ChatRoomEntity) {
        MeetingContainerRouter(presenter: UIApplication.mnz_presentingViewController(), chatRoom: chatRoom, call: call, isSpeakerEnabled: true).start()
    }
    
    private func waitUntilChatStatusComesOnline(forChatId chatId: HandleEntity) async throws {
        let chatStateListener = ChatStateListener(chatId: chatId, connectionState: .online)
        chatStateListener.addListener()
        
        do {
            try await chatStateListener.connectionStateReached()
            chatStateListener.removeListener()
        } catch {
            chatStateListener.removeListener()
            throw error
        }
    }
    
    private var permissionAlertRouter: PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    @objc
    func initiateCallAfterAskingForPermissions(videoCall: Bool) {
        permissionAlertRouter.requestPermissionsFor(videoCall: videoCall) { [weak self] in
            self?.performCall()
        }
    }
}
