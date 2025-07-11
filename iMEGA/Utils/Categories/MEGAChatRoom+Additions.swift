import Foundation
import MEGAFoundation
import MEGAL10n
import MEGASwift

extension MEGAChatRoom: @unchecked @retroactive Sendable {
    var onlineStatus: MEGAChatStatus? {
        guard !isGroup else {
            return nil
        }
        
        return MEGAChatSdk.shared.userOnlineStatus(peerHandle(at: 0))
    }
    
    @objc var isOneToOne: Bool {
        return !isGroup && !isMeeting
    }
    
    var participantNames: String {
        return (0..<peerCount).reduce("") { (result, index) in
            let userHandle = peerHandle(at: index)

            if let name = participantName(forUserHandle: userHandle) {
                let resultName = "\(result)\(name)"
                if index < peerCount - 1 {
                    return "\(resultName), "
                } else {
                    return resultName
                }
            }
            
            return ""
        }
    }
    
    var canAddReactions: Bool {
        if isPublicChat,
        isPreview {
            return false
        } else if ownPrivilege.rawValue <= MEGAChatRoomPrivilege.ro.rawValue {
            return false
        } else {
            return true
        }
    }
    
    @objc func userNickname(atIndex index: UInt) -> String? {
        let userHandle = peerHandle(at: index)
        return userNickname(forUserHandle: userHandle)
    }

    @objc func userNickname(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)
        return user?.nickname
    }
    
    @objc func userDisplayName(forUserHandle userHandle: UInt64) -> String? {
        let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle)

        if let userName = user?.displayName,
            userName.isNotEmpty {
            return userName
        }

        return MEGAChatSdk.shared.userFullnameFromCache(byUserHandle: userHandle)
    }
    
    @objc func chatTitle() -> String {
        if isGroup && !hasCustomTitle && peerCount == 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(creationTimeStamp))
            let dateString = DateFormatter.dateMediumTimeShort().localisedString(from: date)
            return Strings.Localizable.chatCreatedOnS1(dateString)
        } else {
            return title ?? ""
        }
    }
    
    @objc func participantsNames(withMe me: Bool) -> String {
        var meString = Strings.Localizable.me
        if me {
            var myNameOrEmail: String?
            if let myFullname = MEGAChatSdk.shared.myFullname {
                if myFullname.isNotEmptyOrWhitespace {
                    myNameOrEmail = myFullname
                }
            }
            if myNameOrEmail == nil {
                if let myEmail = MEGAChatSdk.shared.myEmail {
                    if myEmail.isNotEmptyOrWhitespace {
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
                participantsNames += participantsNames.isNotEmptyOrWhitespace ? ", \(peerName)" : peerName
                namesAdded += 1
            } else {
                handlesToLoad.append(peerHandle(at: i))
            }
        }
        
        if me {
            participantsNames += participantsNames.isNotEmptyOrWhitespace ? ", \(meString)" : meString
        }
        
        if peerCount > maxParticipantsNames {
            var totalCount = peerCount
            if !me && ownPrivilege.rawValue >= MEGAChatRoomPrivilege.ro.rawValue {
                totalCount += 1
            }
            if participantsNames.isNotEmptyOrWhitespace {
                participantsNames += " and \(totalCount - namesAdded) more"
            } else {
                participantsNames = Strings.Localizable.Chat.Info.numberOfParticipants(Int(totalCount))
            }
        }
        
        if handlesToLoad.isNotEmpty {
            MEGAChatSdk.shared.loadUserAttributes(forChatId: chatId, usersHandles: handlesToLoad as [NSNumber])
        }
        
        return participantsNames
    }
    
    func participantName(atIndex index: UInt) -> String? {
        return participantName(forUserHandle: peerHandle(at: index))
    }
    
    func participantName(forUserHandle userHandle: UInt64) -> String? {
        if let nickName = userNickname(forUserHandle: userHandle) {
            if nickName.isNotEmptyOrWhitespace {
                return nickName
            }
        }
        
        if let firstName = MEGAChatSdk.shared.userFirstnameFromCache(byUserHandle: userHandle) {
            if firstName.isNotEmptyOrWhitespace {
                return firstName
            }
        }
        
        if let lastName = MEGAChatSdk.shared.userLastnameFromCache(byUserHandle: userHandle) {
            if lastName.isNotEmptyOrWhitespace {
                return lastName
            }
        }
        
        if let email = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: userHandle) {
            if email.isNotEmptyOrWhitespace {
                return email
            }
        }
        
        return nil
    }
}
