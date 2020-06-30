
extension MEGASdk {
    @objc func visibleContacts() -> [MEGAUser] {
        let contactsArray = MEGASdkManager.sharedMEGASdk().contacts()
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
}
