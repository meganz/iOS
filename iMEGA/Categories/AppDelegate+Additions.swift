extension AppDelegate {
    
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
            
            if let stringDictionary = request?.megaStringDictionary {
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
        
        guard let handler = requestDelegate else {
            fatalError()
        }


        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: handler)
    }
}

