extension MEGAChatRoom {
    @objc func userNickname(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return userNickname(forUserHandle: userHandle)
    }

    func userNickname(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        return user?.nickname
    }

    func fullName(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return peerFullname(byHandle: userHandle)
    }

    @objc func userDisplayName(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return userDisplayName(forUserHandle: userHandle)
    }

    @objc func userDisplayName(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)

        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }

        return self.peerFullname(byHandle: userHandle)
    }
}
