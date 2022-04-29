
extension MEGASdk {
    @objc var isGuestAccount: Bool {
        guard let email = myUser?.email else {
            return true
        }
        
        return email.isEmpty
    }
    
    @objc func visibleContacts() -> [MEGAUser] {
        let contactsArray = contacts()
        let contactsArraySize = contactsArray.size.intValue
        var visibleContactsArray: [MEGAUser] = []
        var i = 0
        while i < contactsArraySize {
            let user = contactsArray.user(at: i)!
            if user.visibility.rawValue == MEGAUserVisibility.visible.rawValue {
                visibleContactsArray.append(user)
            }
            i += 1
        }
        
        return visibleContactsArray
    }
    
    
    /// An async way to check if the current account is logged in or not.
    /// - Parameters:
    ///   - completion: Callback closure upon completion. The completion closure will be called from an arbitrary background thread.
    @objc(isLoggedInWithCompletion:)
    func isLoggedIn(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            completion(self.isLoggedIn() != 0)
        }
    }
    
    /// An async way to check if there are pending transfers.
    /// - Parameters:
    ///   - completion: Callback closure upon completion. The completion closure will be called from an arbitrary background thread.
    @objc(areTherePendingTransfersWithCompletion:)
    func areTherePendingTransfers(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            completion(self.transfers.size.intValue > 0 || self.transfers.size.intValue > 0)
        }
    }
    
    /// True if storage used greater than storage max, otherwise false
    @objc var isStorageOverquota: Bool {
        guard let accountDetails = mnz_accountDetails else {
            return false
        }
        return accountDetails.storageUsed.int64Value > accountDetails.storageMax.int64Value
    }
}
