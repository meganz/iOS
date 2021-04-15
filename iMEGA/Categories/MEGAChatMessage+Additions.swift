
extension MEGAChatMessage {
    
    @objc(contactNameAtIndex:) func contactName(at index: UInt) -> String? {
        guard usersCount > 0 else {
            return nil
        }
        
        if let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle(at: index)),
            let nickname = user.nickname,
            !nickname.isEmpty {
            return nickname
        }
        
        return userName(at: index)
    }
}
