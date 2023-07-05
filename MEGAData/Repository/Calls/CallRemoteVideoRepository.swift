import MEGADomain

final class CallRemoteVideoRepository: NSObject, CallRemoteVideoRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private var remoteVideos = [RemoteVideoData]()
    private var requestingLowResolutionIds = [HandleEntity]()
    private var requestingHighResolutionIds = [HandleEntity]()
    
    init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    func enableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool, remoteVideoListener: some CallRemoteVideoListenerRepositoryProtocol) {
        guard remoteVideos.notContains(where: { $0.chatId == chatId && $0.clientId == clientId }) else {
            MEGALogDebug("Video for clientId \(clientId) already enabled")
            return
        }
        let remoteVideoData = RemoteVideoData(chatId: chatId, clientId: clientId, hiRes: hiRes, remoteVideoListener: remoteVideoListener)
        remoteVideos.append(remoteVideoData)
        chatSdk.addChatRemoteVideo(chatId, cliendId: clientId, hiRes: hiRes, delegate: remoteVideoData)
        MEGALogDebug("enableRemoteVideo for clientId \(clientId)")
        MEGALogDebug("Number of videos after enable remote video: \(remoteVideos.count)")
    }
    
    func disableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool) {
        guard let remoteVideo = remoteVideos.first(where: { $0.chatId == chatId && $0.clientId == clientId }) else {
            MEGALogDebug("Video for clientId \(clientId) already disabled")
            return
        }
        chatSdk.removeChatRemoteVideo(chatId, cliendId: clientId, hiRes: remoteVideo.hiRes, delegate: remoteVideo)
        guard let index = remoteVideos.firstIndex(of: remoteVideo) else {
            return
        }
        remoteVideos.remove(at: index)
        MEGALogDebug("disableRemoteVideo for clientId \(clientId)")
        MEGALogDebug("Number of videos after disable remote video: \(remoteVideos.count)")
    }
    
    func disableAllRemoteVideos() {
        remoteVideos.forEach { disableRemoteVideo(for: $0.chatId, clientId: $0.clientId, hiRes: $0.hiRes) }
        MEGALogDebug("Removed all remote video listeners")
    }
    
    func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        
        if requestingHighResolutionIds.contains(clientId) {
            MEGALogDebug("High resolution for \(clientId) already requested")
            return
        }
        requestingHighResolutionIds.append(clientId)
        
        chatSdk.requestHiResVideo(forChatId: chatId, clientId: clientId, delegate: MEGAChatResultRequestDelegate { [self] result in
            switch result {
            case .success:
                MEGALogDebug("Success to request high resolution video for clientId: \(clientId)")
                completion?(.success)
            case .failure:
                MEGALogError("Fail to request high resolution video for clientId: \(clientId)")
                completion?(.failure(.requestResolutionVideoChange))
            }
            guard let index = self.requestingHighResolutionIds.firstIndex(of: clientId) else {
                return
            }
            self.requestingHighResolutionIds.remove(at: index)
        })
    }
    
    func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {

        chatSdk.stopHiResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success:
                MEGALogDebug("Success to stop high resolution video for clientId: \(clientId)")
                completion?(.success)
            case .failure:
                MEGALogError("Fail to stop high resolution video for clientId: \(clientId)")
                completion?(.failure(.stopHighResolutionVideo))
            }
        })
    }
    
    func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        
        if requestingLowResolutionIds.contains(clientId) {
            MEGALogDebug("Low resolution for \(clientId) already requested")
            return
        } else {
            requestingLowResolutionIds.append(clientId)
        }
        
        chatSdk.requestLowResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success:
                MEGALogDebug("Success to request low resolution video for clientId: \(clientId)")
                completion?(.success)
            case .failure:
                MEGALogError("Fail to request low resolution video for clientId: \(clientId)")
                completion?(.failure(.requestResolutionVideoChange))
            }
            if let index = self.requestingLowResolutionIds.firstIndex(of: clientId) {
                self.requestingLowResolutionIds.remove(at: index)
            }
        })
    }
    
    func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        chatSdk.stopLowResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: MEGAChatResultRequestDelegate { result in
            switch result {
            case .success:
                MEGALogDebug("Success to stop low resolution video for clientId: \(clientId)")
                completion?(.success)
            case .failure:
                MEGALogError("Fail to stop low resolution video for clientId: \(clientId)")
                completion?(.failure(.stopLowResolutionVideo))
            }
        })
    }
}

final class RemoteVideoData: NSObject, MEGAChatVideoDelegate {
    let chatId: HandleEntity
    let clientId: HandleEntity
    var hiRes: Bool = false
    var remoteVideoListener: (any CallRemoteVideoListenerRepositoryProtocol)?
    
    init(chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool, remoteVideoListener: some CallRemoteVideoListenerRepositoryProtocol) {
        self.chatId = chatId
        self.clientId = clientId
        self.hiRes = hiRes
        self.remoteVideoListener = remoteVideoListener
    }
    
    func onChatVideoData(_ api: MEGAChatSdk, chatId: UInt64, width: Int, height: Int, buffer: Data) {
        remoteVideoListener?.remoteVideoFrameData(clientId: clientId, width: width, height: height, buffer: buffer)
    }
}
