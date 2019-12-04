extension AppDelegate {
    
    private func requestNickname(forUser user: MEGAUser,
                                 context: NSManagedObjectContext,
                                 group: DispatchGroup) {
        let requestDelegate = MEGAGenericRequestDelegate { request, error in
            if let nickname = request?.name,
                nickname.isEmpty == false {
                MEGAStore.shareInstance()?.updateUser(withUserHandle: user.handle,
                                                      nickname: nickname,
                                                      context: context)
            } else if error != nil && error!.type == .apiENoent {
                MEGAStore.shareInstance()?.updateUser(withUserHandle: user.handle,
                                                      nickname: nil,
                                                      context: context)
            }
            
            group.leave()
        }
        
        guard let handler = requestDelegate else {
            fatalError()
        }
        
        group.enter()
        user.fetchNickname(completionHandler: handler)
    }
    
    @objc func fetchContactsNickname() {
        guard let megaStore = MEGAStore.shareInstance(),
            let privateQueueContext = megaStore.childPrivateQueueContext else {
                return
        }
        
        privateQueueContext.perform {
            guard let contacts = MEGASdkManager.sharedMEGASdk()?.contacts() else {
                return
            }
            
            let fetchGroup = DispatchGroup()
            (0..<contacts.size.intValue).forEach { index in
                if let user = contacts.user(at: index),
                    user.visibility == .visible {
                    self.requestNickname(forUser: user,
                                         context: privateQueueContext,
                                         group: fetchGroup)
                }
            }
            
            fetchGroup.wait()
            megaStore.save(privateQueueContext)
            
            OperationQueue.main.addOperation {
                NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded),
                                                object: nil)
            }
        }
    }
}
