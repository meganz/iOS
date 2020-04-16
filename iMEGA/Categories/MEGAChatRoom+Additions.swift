
import Foundation

extension MEGAChatRoom {
    @objc func userNickname(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return userNickname(forUserHandle: userHandle)
    }
    
    func userNickname(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        return user?.nickname
    }
    
    @objc func userDisplayName(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        
        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }
        
        return self.peerFullname(byHandle: userHandle)
    }
    
    @objc func participantsNames(withMe me: Bool) -> String {
        var meString = AMLocalizedString("me", "The title for my message in a chat. The message was sent from yourself.")
        if me {
            var myNameOrEmail: String?
            if let myFullname = MEGASdkManager.sharedMEGAChatSdk()?.myFullname {
                if !myFullname.mnz_isEmpty() {
                    myNameOrEmail = myFullname
                }
            }
            if myNameOrEmail == nil {
                if let myEmail = MEGASdkManager.sharedMEGAChatSdk()?.myEmail {
                    if !myEmail.mnz_isEmpty() {
                        myNameOrEmail = myEmail
                    }
                }
            }
            if let myParticipantName = myNameOrEmail {
                meString = "\(myParticipantName) (\(meString))"
            }
        }
        
        if peerCount == 0 {
            return me ? meString : ""
        }
        
        let maxParticipantsNames: UInt = me ? 3 : 4
        let limit = peerCount > maxParticipantsNames ? maxParticipantsNames - 1 : min(peerCount, maxParticipantsNames)
        
        var handlesToLoad = [CUnsignedLongLong]()
        var participantsNames = ""
        var namesAdded: UInt = 0
        for i in (0..<limit) {
            if let peerName = participantName(atIndex: i) {
                participantsNames += participantsNames.mnz_isEmpty() ? peerName : ", \(peerName)"
                namesAdded += 1
            } else {
                handlesToLoad.append(peerHandle(at: i))
            }
        }
        
        if me {
            participantsNames += participantsNames.mnz_isEmpty() ? meString : ", \(meString)"
        }
        
        if peerCount > maxParticipantsNames {
            var totalCount = peerCount
            if !me && ownPrivilege.rawValue >= MEGAChatRoomPrivilege.ro.rawValue {
                totalCount += 1
            }
            if participantsNames.mnz_isEmpty() {
                participantsNames = AMLocalizedString("%d participants", "Plural of participant. 2 participants").replacingOccurrences(of: "%d", with: "\(totalCount)")
            } else {
                participantsNames += " and \(totalCount - namesAdded) more"
            }
        }
        
        if handlesToLoad.count > 0 {
            MEGASdkManager.sharedMEGAChatSdk()?.loadUserAttributes(forChatId: chatId, usersHandles: handlesToLoad as [NSNumber], authorizationToken: authorizationToken)
        }
        
        return participantsNames
    }
    
    func participantName(atIndex index:UInt) -> String? {
        return participantName(forUserHandle: peerHandle(at: index))
    }
    
    @objc func participantName(forUserHandle userHandle: UInt64) -> String? {
        if let nickName = userNickname(forUserHandle: userHandle) {
            if !nickName.mnz_isEmpty() {
                return nickName
            }
        }
        
        if let firstName = peerFirstname(byHandle: userHandle) {
            if !firstName.mnz_isEmpty() {
                return firstName
            }
        }
        
        if let lastName = peerLastname(byHandle: userHandle) {
            if !lastName.mnz_isEmpty() {
                return lastName
            }
        }
        
        if let email = peerEmail(byHandle: userHandle) {
            if !email.mnz_isEmpty() {
                return email
            }
        }
        
        return nil
    }
}
