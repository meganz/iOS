
extension MEGAChatRoom {
    @objc func userNickname(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return userNickname(forUserHandle: userHandle)
    }
    
    @objc func userNickname(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        return user?.nickname
    }
    
    func fullName(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return fullname(forUserHandle: userHandle)
    }
    
    func fullname(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        return user?.fullName
    }
}
