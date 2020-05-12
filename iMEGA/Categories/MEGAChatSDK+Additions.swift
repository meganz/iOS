extension MEGAChatSdk {
    @objc var mnz_existsActiveCall: Bool {
        return ((self.chatCalls(withState: .undefined)?.size ?? 0) - (self.chatCalls(withState: .userNoPresent)?.size ?? 0)) > 0
    }
    
    @objc func mnz_createChatRoom(userHandle: UInt64, completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void) {
        let peerList = MEGAChatPeerList()
        peerList.addPeer(withHandle: userHandle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
        let delegate = createChatDelegate { (chatRoom) in
            completion(chatRoom)
        }
        
        createChatGroup(false, peers: peerList, delegate: delegate)
    }
    
    @objc func mnz_createChatRoom(usersArray: Array<MEGAUser>, title: String?, completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void) {
        let peerList = MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: usersArray)
        let delegate = createChatDelegate { (chatRoom) in
            completion(chatRoom)
        }
        
        createChatGroup(true, peers: peerList, title:title, delegate: delegate)
    }
    
    private func createChatDelegate(completion: @escaping(_ chatRoom: MEGAChatRoom) -> Void) -> MEGAChatGenericRequestDelegate {
        let delegate = MEGAChatGenericRequestDelegate { (request, error) in
            if error.type.rawValue == MEGAChatErrorType.MEGAChatErrorTypeOk.rawValue {
                guard let chatRoom = self.chatRoom(forChatId: request.chatHandle) else {
                    MEGALogError("Error when getting the newly created chat room with chat handle: \(request.chatHandle)")
                    return
                }
                completion(chatRoom)
            } else {
                MEGALogError("Error when creating the chat room: \(error)")
            }
        }
        
        return delegate
    }
}
