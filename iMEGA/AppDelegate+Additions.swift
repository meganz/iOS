import Foundation
import SafariServices

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if  visibleViewController is AddPhoneNumberViewController ||
            visibleViewController is InitialLaunchViewController ||
            visibleViewController is LaunchViewController ||
            visibleViewController is SMSVerificationViewController ||
            visibleViewController is VerificationCodeViewController ||
            visibleViewController is CreateAccountViewController ||
            visibleViewController is UpgradeTableViewController ||
            visibleViewController is OnboardingViewController ||
            visibleViewController is UIAlertController ||
            visibleViewController is VerifyEmailViewController ||
            visibleViewController is LoginViewController ||
            visibleViewController is SFSafariViewController { return }

        if MEGASdkManager.sharedMEGASdk().isBusinessAccount && MEGASdkManager.sharedMEGASdk().businessStatus != .active {
            return
        }
        
        if MEGASdkManager.sharedMEGASdk().smsAllowedState() != .optInAndUnblock { return }

        if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() != nil { return }

        if UserDefaults.standard.bool(forKey: "dontShowAgainAddPhoneNumber") {
            return
        }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }

        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        var hideDontShowAgain = true
        let timesAddPhoneNumberShowed = UserDefaults.standard.integer(forKey: "timesAddPhoneNumberShowed")
        if timesAddPhoneNumberShowed >= MEGAOptOutOfAddYourPhoneNumberMinCount {
            hideDontShowAgain = false
        }
        UserDefaults.standard.set(timesAddPhoneNumberShowed + 1, forKey: "timesAddPhoneNumberShowed")
        AddPhoneNumberRouter(hideDontShowAgain: hideDontShowAgain, presenter: UIApplication.mnz_presentingViewController()).start()
    }

    @objc func showEnableTwoFactorAuthenticationIfNeeded() {
        if UserDefaults.standard.bool(forKey: "twoFactorAuthenticationAlreadySuggested") {
            return
        }

        MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: MEGASdkManager.sharedMEGASdk().myEmail ?? "", delegate: MEGAGenericRequestDelegate.init(completion: { (request, _) in
            if request.flag {
                return //Two Factor Authentication Enabled
            }

            if UIApplication.mnz_visibleViewController() is AddPhoneNumberViewController || UIApplication.mnz_visibleViewController() is CustomModalAlertViewController || UIApplication.mnz_visibleViewController() is BusinessExpiredViewController || (MEGASdkManager.sharedMEGASdk().isBusinessAccount && MEGASdkManager.sharedMEGASdk().businessStatus != .active) {
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
    
    @objc func showCookieDialogIfNeeded() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        
        if cookieSettingsUseCase.cookieBannerEnabled() {
            cookieSettingsUseCase.cookieSettings { [weak self] in
                switch $0 {
                case .success(_): break //Cookie settings already set
                    
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
        
    private func showCookieDialog() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if visibleViewController is CustomModalAlertViewController ||
           visibleViewController is BusinessExpiredViewController {
            return
        }
        
        let cookieDialogCustomModalAlert = CustomModalAlertViewController()
        cookieDialogCustomModalAlert.configureForCookieDialog()

        UIApplication.mnz_presentingViewController().present(cookieDialogCustomModalAlert, animated: true, completion: nil)
    }

    @objc func fetchContactsNickname() {
        guard let megaStore = MEGAStore.shareInstance(),
              let privateQueueContext = megaStore.stack?.newBackgroundContext() else {
            return
        }

        privateQueueContext.perform {
            self.requestNicknames(context: privateQueueContext, store: megaStore) {
                OperationQueue.main.addOperation {
                    NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded), object: nil)
                }
            }
        }
    }

    private func requestNicknames(context: NSManagedObjectContext, store: MEGAStore, completionBlock: @escaping (() -> Void)) {
        let requestDelegate = MEGAGenericRequestDelegate { request, error in
            if error.type != .apiOk {
                return
            }

            if let stringDictionary = request.megaStringDictionary {
                stringDictionary.forEach { key, value in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: key)

                    if let nickname = value.base64URLDecoded {
                        store.updateUser(withUserHandle: userHandle, nickname: nickname, context: context)
                    }
                }

                store.save(context)
                completionBlock()
            }
        }

        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: requestDelegate)
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
            if suspensionType == .businessDisabled {
                message = NSLocalizedString("Your account has been disabled by your administrator. Please contact your business account administrator for further details.", comment: "Error message appears to sub-users of a business account when they try to login and they are disabled.")
            } else if suspensionType == .businessRemoved {
                message = NSLocalizedString("Your account has been removed by your administrator. Please contact your business account administrator for further details.", comment: "An error message which appears to sub-users of a business account when they try to login and they are deleted.")
            } else {
                message = NSLocalizedString("accountBlocked", comment: "Error message when trying to login and the account is blocked")
            }
            
            let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message:message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel) { _ in
                MEGASdkManager.sharedMEGASdk().logout()
            })
            UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Config Cookie Settings

extension AppDelegate {
    @objc func checkCookieSettingsUpdate(in userList: MEGAUserList) {
        guard let size = userList.size?.intValue else {
            return
        }
        
        for index in 0..<size {
            let user = userList.user(at: index)
            if (user?.changes != nil) {
                if user?.isOwnChange == 0 { //If the change is external
                    if user?.handle == MEGASdkManager.sharedMEGASdk().myUser?.handle {
                        if ((user?.hasChangedType(.cookieSetting)) != nil) {
                            configAppWithNewCookieSettings()
                        }
                    }
                }
            }
        }
    }
    
    private func configAppWithNewCookieSettings() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        cookieSettingsUseCase.cookieSettings { [weak self] in
            switch $0 {
            case .success(let bitmap):
                let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
                cookieSettingsUseCase.setCrashlyticsEnabled(cookiesBitmap.contains(.analytics))
                
            case .failure(_): break
            }
        }
    }
}
