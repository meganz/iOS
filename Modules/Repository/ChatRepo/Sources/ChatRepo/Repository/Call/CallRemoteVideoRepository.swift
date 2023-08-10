import MEGAChatSdk
import MEGADomain

public final class CallRemoteVideoRepository: NSObject, CallRemoteVideoRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private var remoteVideos = [RemoteVideoData]()
    private var requestingLowResolutionIds = [HandleEntity]()
    private var requestingHighResolutionIds = [HandleEntity]()
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func enableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool, remoteVideoListener: some CallRemoteVideoListenerRepositoryProtocol) {
        guard remoteVideos.notContains(where: { $0.chatId == chatId && $0.clientId == clientId }) else {
            return
        }
        let remoteVideoData = RemoteVideoData(chatId: chatId, clientId: clientId, hiRes: hiRes, remoteVideoListener: remoteVideoListener)
        remoteVideos.append(remoteVideoData)
        chatSdk.addChatRemoteVideo(chatId, cliendId: clientId, hiRes: hiRes, delegate: remoteVideoData)
    }
    
    public func disableRemoteVideo(for chatId: HandleEntity, clientId: HandleEntity, hiRes: Bool) {
        guard let remoteVideo = remoteVideos.first(where: { $0.chatId == chatId && $0.clientId == clientId }) else {
            return
        }
        chatSdk.removeChatRemoteVideo(chatId, cliendId: clientId, hiRes: remoteVideo.hiRes, delegate: remoteVideo)
        guard let index = remoteVideos.firstIndex(of: remoteVideo) else {
            return
        }
        remoteVideos.remove(at: index)
    }
    
    public func disableAllRemoteVideos() {
        remoteVideos.forEach { disableRemoteVideo(for: $0.chatId, clientId: $0.clientId, hiRes: $0.hiRes) }
    }
    
    public func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        
        if requestingHighResolutionIds.contains(clientId) {
            return
        }
        requestingHighResolutionIds.append(clientId)
        
        chatSdk.requestHiResVideo(forChatId: chatId, clientId: clientId, delegate: ChatRequestDelegate { [self] result in
            switch result {
            case .success:
                completion?(.success)
            case .failure:
                completion?(.failure(.requestResolutionVideoChange))
            }
            guard let index = self.requestingHighResolutionIds.firstIndex(of: clientId) else {
                return
            }
            self.requestingHighResolutionIds.remove(at: index)
        })
    }
    
    public func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {

        chatSdk.stopHiResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion?(.success)
            case .failure:
                completion?(.failure(.stopHighResolutionVideo))
            }
        })
    }
    
    public func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        
        if requestingLowResolutionIds.contains(clientId) {
            return
        } else {
            requestingLowResolutionIds.append(clientId)
        }
        
        chatSdk.requestLowResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion?(.success)
            case .failure:
                completion?(.failure(.requestResolutionVideoChange))
            }
            if let index = self.requestingLowResolutionIds.firstIndex(of: clientId) {
                self.requestingLowResolutionIds.remove(at: index)
            }
        })
    }
    
    public func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion? = nil) {
        chatSdk.stopLowResVideo(forChatId: chatId, clientIds: [NSNumber(value: clientId)], delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion?(.success)
            case .failure:
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
