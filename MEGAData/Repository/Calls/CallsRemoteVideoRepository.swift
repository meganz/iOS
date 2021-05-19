
final class CallsRemoteVideoRepository: NSObject, CallsRemoteVideoRepositoryProtocol {
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()

    private var remoteVideos = [RemoteVideoData]()
    
    func enableRemoteVideo(for chatId: MEGAHandle, clientId: MEGAHandle, hiRes: Bool, remoteVideoListener: CallsRemoteVideoListenerRepositoryProtocol) {
        let remoteVideoData = RemoteVideoData(chatId: chatId, clientId: clientId, hiRes: hiRes, remoteVideoListener: remoteVideoListener)
        remoteVideos.append(remoteVideoData)
        chatSdk.addChatRemoteVideo(chatId, cliendId: clientId, hiRes: hiRes, delegate: remoteVideoData)
        MEGALogDebug("Number of videos after enable remote video: \(remoteVideos.count) is high resolution: \(hiRes)")
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
        MEGALogDebug("Number of videos after disable remote video: \(remoteVideos.count) was high resolution: \(hiRes)")
    }
    
    func disableAllRemoteVideos() {
        remoteVideos.forEach { chatSdk.removeChatRemoteVideo($0.chatId, cliendId: $0.clientId, hiRes: $0.hiRes, delegate: $0) }
        remoteVideos.removeAll()
        MEGALogDebug("Removed all remote video listeners")
    }
    
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.requestHiResVideo(forChatId: chatId, clientId: clientId, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                MEGALogDebug("Success to request high resolution video")
                completion(.success)
            case .failure(_):
                MEGALogError("Fail to request high resolution video")
                completion(.failure(.requestResolutionVideoChange))
            }
        })
    }
    
    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        let clientIdsMapped = clientIds.map { NSNumber(value: $0) }

        chatSdk.stopHiResVideo(forChatId: chatId, clientIds: clientIdsMapped, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                MEGALogDebug("Success to stop high resolution video")
                completion(.success)
            case .failure(_):
                MEGALogError("Fail to stop high resolution video")
                completion(.failure(.stopHighResolutionVideo))
            }
        })
    }
    
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        let clientIdsMapped = clientIds.map { NSNumber(value: $0) }
        
        chatSdk.requestLowResVideo(forChatId: chatId, clientIds: clientIdsMapped, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                MEGALogDebug("Success to request low resolution video")
                completion(.success)
            case .failure(_):
                MEGALogError("Fail to request low resolution video")
                completion(.failure(.requestResolutionVideoChange))
            }
        })
    }
    
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        let clientIdsMapped = clientIds.map { NSNumber(value: $0) }

        chatSdk.stopLowResVideo(forChatId: chatId, clientIds: clientIdsMapped, delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success(_):
                MEGALogDebug("Success to stop low resolution video")
                completion(.success)
            case .failure(_):
                MEGALogError("Fail to stop low resolution video")
                completion(.failure(.stopLowResolutionVideo))
            }
        })
    }
}

final class RemoteVideoData: NSObject, MEGAChatVideoDelegate {
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
