
extension MEGAChatPeerList {
    @objc class func mnz_standardPrivilegePeerList(usersArray: Array<MEGAUser>) -> MEGAChatPeerList {
        let peerList = MEGAChatPeerList()
        for user: MEGAUser in usersArray {
            peerList.addPeer(withHandle: user.handle, privilege: MEGAChatRoomPrivilege.standard.rawValue)
        }
        
        return peerList
    }
}
