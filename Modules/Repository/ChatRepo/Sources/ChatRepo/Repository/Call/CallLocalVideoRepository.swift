import MEGAChatSdk
import MEGADomain

public final class CallLocalVideoRepository: NSObject, CallLocalVideoRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private var localVideoCallbacksDelegate: (any CallLocalVideoListenerRepositoryProtocol)?

    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.enableVideo(forChat: chatId, delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion(.success)
            case .failure:
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        })
    }
    
    public func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.disableVideo(forChat: chatId, delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion(.success)
            case .failure:
                completion(.failure(.chatLocalVideoNotDisabled))
            }
        })
    }
    
    public func addLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol) {
        chatSdk.addChatLocalVideo(chatId, delegate: self)
        chatSdk.add(self)
        localVideoCallbacksDelegate = localVideoListener
    }
    
    public func removeLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol) {
        chatSdk.removeChatLocalVideo(chatId, delegate: self)
        chatSdk.remove(self)
        localVideoCallbacksDelegate = nil
    }
    
    public func videoDeviceSelected() -> String? {
        chatSdk.videoDeviceSelected()
    }
    
    public func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        chatSdk.setChatVideoInDevices(localizedName, delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion(.success)
            case .failure:
                completion(.failure(GenericErrorEntity()))
            }
        })
    }
    
    public func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.openVideoDevice(with: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion(.success)
            case .failure:
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        })
    }
    
    public func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.releaseVideoDevice(with: ChatRequestDelegate { result in
            switch result {
            case .success:
                completion(.success)
            case .failure:
                completion(.failure(.chatLocalVideoNotDisabled))
            }
        })
    }
}

extension CallLocalVideoRepository: MEGAChatVideoDelegate {
    public func onChatVideoData(_ api: MEGAChatSdk, chatId: UInt64, width: Int, height: Int, buffer: Data) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
}

extension CallLocalVideoRepository: MEGAChatRequestDelegate {
    public func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if request.type == .changeVideoStream {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
