
final class CallsLocalVideoRepository: NSObject, CallsLocalVideoRepositoryProtocol {
    
    private let chatSdk = MEGASdkManager.sharedMEGAChatSdk()
    private var localVideoCallbacksDelegate: CallsLocalVideoListenerRepositoryProtocol?

    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.enableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { error in
            if error?.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        }))
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.disableVideo(forChat: chatId, delegate: MEGAChatEnableDisableVideoRequestDelegate(completion: { error in
            if error?.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotDisabled))
            }
        }))
    }
    
    func addLocalVideo(for chatId: MEGAHandle, localVideoListener: CallsLocalVideoListenerRepositoryProtocol) {
        chatSdk.addChatLocalVideo(chatId, delegate: self)
        chatSdk.add(self)
        localVideoCallbacksDelegate = localVideoListener
    }
    
    func removeLocalVideo(for chatId: MEGAHandle, localVideoListener: CallsLocalVideoListenerRepositoryProtocol) {
        chatSdk.removeChatLocalVideo(chatId, delegate: self)
        chatSdk.remove(self)
        localVideoCallbacksDelegate = nil
    }
    
    func videoDeviceSelected() -> String? {
        chatSdk.videoDeviceSelected()
    }
    
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionError>) -> Void) {
        let delegate =  MEGAChatGenericRequestDelegate { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.generic))
            }
        }
        
        chatSdk.setChatVideoInDevices(localizedName, delegate: delegate)
    }
    
    func openVideoDevice(completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        chatSdk.openVideoDevice(with: MEGAChatGenericRequestDelegate(completion: { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                completion(.success)
            } else {
                completion(.failure(.chatLocalVideoNotEnabled))
            }
        }))
    }
    
    func releaseVideoDevice(completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
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

extension CallsLocalVideoRepository: MEGAChatVideoDelegate {
    func onChatVideoData(_ api: MEGAChatSdk!, chatId: UInt64, width: Int, height: Int, buffer: Data!) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
}

extension CallsLocalVideoRepository: MEGAChatRequestDelegate {
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if request.type == .changeVideoStream {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
