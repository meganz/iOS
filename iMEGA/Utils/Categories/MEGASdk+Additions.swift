
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
    
    /// True if storage used greater than storage max, otherwise false
    @objc var isStorageOverquota: Bool {
        guard let accountDetails = mnz_accountDetails else {
            return false
        }
        return accountDetails.storageUsed.int64Value > accountDetails.storageMax.int64Value
    }
}
