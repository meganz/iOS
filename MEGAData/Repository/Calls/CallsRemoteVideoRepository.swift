
final class CallsRemoteVideoRepository: NSObject, CallsRemoteVideoRepositoryProtocol {
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()

    private var remoteVideos = [RemoteVideoData]()
    
    func enableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool, remoteVideoListener: CallsRemoteVideoListenerRepositoryProtocol) {
        let remoteVideoData = RemoteVideoData(chatId: chatId, clientId: clientId, hiRes: hiRes, remoteVideoListener: remoteVideoListener)
        remoteVideos.append(remoteVideoData)
        chatSdk.addChatRemoteVideo(chatId, cliendId: clientId, hiRes: hiRes, delegate: remoteVideoData)
    }
    
    func disableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool) {
        guard let remoteVideo = remoteVideos.filter({ $0.chatId == chatId && $0.clientId == clientId }).first else {
            return
        }
        chatSdk.removeChatRemoteVideo(chatId, cliendId: clientId, hiRes: hiRes, delegate: remoteVideo)
        guard let index = remoteVideos.firstIndex(of: remoteVideo) else {
            return
        }
        remoteVideos.remove(at: index)
    }
    
    func disableAllRemoteVideos() {
        remoteVideos.forEach { chatSdk.removeChatRemoteVideo($0.chatId, cliendId: $0.clientId, hiRes: $0.hiRes, delegate: $0) }
        remoteVideos.removeAll()
    }
    
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.requestHiResVideo(forChatId: chatId, clientId: clientId, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(_):
                completion(.failure(.requestResolutionVideoChange))
            }
        })
    }
    
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        let clientIdsMapped = clientIds.map { NSNumber(value: $0) }
        
        chatSdk.requestLowResVideo(forChatId: chatId, clientIds: clientIdsMapped, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                completion(.success)
            case .failure(_):
                completion(.failure(.requestResolutionVideoChange))
            }
        })
    }
}

class RemoteVideoData: NSObject, MEGAChatVideoDelegate {
    let chatId: MEGAHandle
    let clientId: MEGAHandle
    var hiRes: Bool = false
    var remoteVideoListener: CallsRemoteVideoListenerRepositoryProtocol?
    
    init(chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool, remoteVideoListener: CallsRemoteVideoListenerRepositoryProtocol) {
        self.chatId = chatId
        self.clientId = clientId
        self.hiRes = hiRes
        self.remoteVideoListener = remoteVideoListener
    }
    
    func onChatVideoData(_ api: MEGAChatSdk!, chatId: UInt64, width: Int, height: Int, buffer: Data!) {
        remoteVideoListener?.remoteVideoFrameData(clientId: clientId, width: width, height: height, buffer: buffer)
    }
}
