import Foundation

final class MeetingCreatingRepository: NSObject, MeetingCreatingRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private let sdk = MEGASdkManager.sharedMEGASdk()

    func setChatVideoInDevices(device: String) {
        chatSdk.setChatVideoInDevices(device)
    }
    
    func openVideoDevice() {
        chatSdk.openVideoDevice()
    }
    
    func videoDevices() -> [String] {
        chatSdk.chatVideoInDevices()?.toArray() ?? []
    }
    
    func releaseDevice() {
        chatSdk.releaseVideoDevice()
    }
    
    func getUsername() -> String {
        let user = MEGAStore.shareInstance().fetchUser(withEmail: sdk.myEmail)
        if let userName = user?.displayName,
            userName.count > 0 {
            return userName
        }
        
        return chatSdk.userFullnameFromCache(byUserHandle:  sdk.myUser?.handle ?? 0)

    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<MEGAChatRoom, CallsErrorEntity>) -> Void) {
        
        let delegate = MEGAChatGenericRequestDelegate { [weak self] (request, error) in
            guard let chatroom = self?.chatSdk.chatRoom(forChatId: request.chatHandle) else {
                return
            }
            self?.chatSdk.startChatCall(chatroom.chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: MEGAChatStartCallRequestDelegate(completion: { [weak self] (chatError) in
                if chatError?.type == .MEGAChatErrorTypeOk {
                    guard (self?.chatSdk.chatCall(forChatId: request.chatHandle)) != nil else {
                        completion(.failure(.generic))
                        return
                    }
                    completion(.success(chatroom))
                } else {
                    completion(.failure(.generic))
                }
            }))

        }
        let chatPeers = MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: [])
        
        chatSdk.createPublicChat(withPeers: chatPeers, title: meetingName, delegate: delegate)
    }

    func addChatLocalVideo(delegate: MEGAChatVideoDelegate) {
       chatSdk.addChatLocalVideo(123, delegate: delegate)
    }


}
