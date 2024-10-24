/// Helper file to be able to fetch chat participant names from legacy code or view controllers that lack architecture.
/// Should be removed after refactor objc code and created view models for views related to chat

import MEGADomain

func participantName(forUserHandle userHandle: UInt64) -> String? {
    if let nickName = userNickname(forUserHandle: userHandle) {
        if !nickName.mnz_isEmpty() {
            return nickName
        }
    }
    
    if let firstName = MEGAChatSdk.shared.userFirstnameFromCache(byUserHandle: userHandle) {
        if !firstName.mnz_isEmpty() {
            return firstName
        }
    }
    
    if let lastName = MEGAChatSdk.shared.userLastnameFromCache(byUserHandle: userHandle) {
        if !lastName.mnz_isEmpty() {
            return lastName
        }
    }
    
    if let email = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: userHandle) {
        if !email.mnz_isEmpty() {
            return email
        }
    }
    
    return nil
}

func userNickname(forUserHandle userHandle: UInt64) -> String? {
    let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
    return user?.nickname
}

func userDisplayName(forUserHandle userHandle: UInt64) -> String? {
    let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)

    if let userName = user?.displayName,
        userName.isNotEmpty {
        return userName
    }

    return MEGAChatSdk.shared.userFullnameFromCache(byUserHandle: userHandle)
}

func participantNames(for chatRoom: ChatRoomEntity) -> String {
    return (0..<chatRoom.peerCount).reduce("") { (result, index) in
        let userHandle = chatRoom.peers[Int(index)].handle

        if let name = participantName(forUserHandle: userHandle) {
            let resultName = "\(result)\(name)"
            if index < chatRoom.peerCount - 1 {
                return "\(resultName), "
            } else {
                return resultName
            }
        }
        
        return ""
    }
}
