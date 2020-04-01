
extension MEGAChatRoom {
    var onlineStatus: MEGAChatStatus? {
        if isGroup {
            return nil
        }
        
        return MEGASdkManager.sharedMEGAChatSdk()?.userOnlineStatus(peerHandle(at: 0))
    }
    
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
    
    var participantsNames: String {
        return (0..<peerCount).reduce("") { (result, index) in
            if let nickname = userNickname(atIndex: index)?.trim {
                let appendResult = (index == peerCount-1) ? nickname : "\(nickname), "
                return result + appendResult
            } else if let peerFirstname = peerFirstname(at: index)?.trim {
                let appendResult = (index == peerCount-1) ? peerFirstname : "\(peerFirstname), "
                return result + appendResult
            } else if let peerLastname = peerLastname(at: index)?.trim {
                let appendResult = (index == peerCount-1) ? peerLastname : "\(peerLastname), "
                return result + appendResult
            } else if let peerEmail = peerEmail(byHandle: peerHandle(at: index))?.trim {
                let appendResult = (index == peerCount-1) ? peerEmail : "\(peerEmail), "
                return result + appendResult
            }
            
            return ""
        }
    }
    
    func avatarImage(delegate: MEGARequestDelegate?) -> UIImage? {
        guard peerCount == 1,
            let peerEmail = peerEmail(byHandle: peerHandle(at: 0)),
            let user = MEGASdkManager.sharedMEGASdk()?.contact(forEmail: peerEmail) else {
                return nil
        }
        
        return user.avatarImage(withDelegate: delegate)
    }
}
