import MEGADomain

final class CallLocalVideoRepository: NSObject, CallLocalVideoRepositoryProtocol {
    
    private let chatSdk: MEGAChatSdk
    private var localVideoCallbacksDelegate: CallLocalVideoListenerRepositoryProtocol?

    init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.enableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { error in
            if error?.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        }))
    }
    
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.disableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { error in
            if error?.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotDisabled))
            }
        }))
    }
    
    func addLocalVideo(for chatId: HandleEntity, localVideoListener: CallLocalVideoListenerRepositoryProtocol) {
        chatSdk.addChatLocalVideo(chatId, delegate: self)
        chatSdk.add(self)
        localVideoCallbacksDelegate = localVideoListener
    }
    
    func removeLocalVideo(for chatId: HandleEntity, localVideoListener: CallLocalVideoListenerRepositoryProtocol) {
        chatSdk.removeChatLocalVideo(chatId, delegate: self)
        chatSdk.remove(self)
        localVideoCallbacksDelegate = nil
    }
    
    func videoDeviceSelected() -> String? {
        chatSdk.videoDeviceSelected()
    }
    
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionErrorEntity>) -> Void) {
        let delegate =  MEGAChatGenericRequestDelegate { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.generic))
            }
        }
        
        chatSdk.setChatVideoInDevices(localizedName, delegate: delegate)
    }
    
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.openVideoDevice(with: MEGAChatGenericRequestDelegate(completion: { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        }))
    }
    
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        chatSdk.releaseVideoDevice(with: MEGAChatGenericRequestDelegate(completion: { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                if error.type == .MEGAChatErrorTypeOk {
                    completion(.success)
                } else {
                    completion(.failure(.chatLocalVideoNotDisabled))
                }
            }
        }))
    }
}

extension CallLocalVideoRepository: MEGAChatVideoDelegate {
    func onChatVideoData(_ api: MEGAChatSdk, chatId: UInt64, width: Int, height: Int, buffer: Data) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
}

extension CallLocalVideoRepository: MEGAChatRequestDelegate {
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if request.type == .changeVideoStream {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
