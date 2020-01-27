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
            visibleViewController is UIAlertController { return }
        
        if MEGASdkManager.sharedMEGASdk()?.smsAllowedState() != .optInAndUnblock { return }
        
        guard !MEGASdkManager.sharedMEGASdk().hasVerifiedPhoneNumber else { return }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        
        let addPhoneNumberController = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "AddPhoneNumberViewControllerID")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
    }
    
    @objc func fetchContactsNickname() {
        guard let megaStore = MEGAStore.shareInstance(),
            let privateQueueContext = megaStore.childPrivateQueueContext else {
                return
        }
        
        privateQueueContext.perform {
            self.requestNicknames(context: privateQueueContext, store: megaStore) {
                OperationQueue.main.addOperation {
                    NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded),
                                                    object: nil)
                }
            }
        }
    }
    
    private func requestNicknames(context: NSManagedObjectContext,
                                  store: MEGAStore, completionBlock: @escaping (() -> Void)) {
        let requestDelegate = MEGAGenericRequestDelegate { request, error in
            
            if let stringDictionary = request.megaStringDictionary {
                stringDictionary.forEach { key, value in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: key)
                    
                    if let nickname = value.base64URLDecoded {
                        store.updateUser(withUserHandle: userHandle,
                                         nickname: nickname,
                                         context: context)
                    }
                }
                
                store.save(context)
                completionBlock()
            }
            
        }

        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: requestDelegate)
    }
}

