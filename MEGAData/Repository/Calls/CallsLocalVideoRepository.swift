
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
    
    func selectCamera(withLocalizedName localizedName: String) {
        chatSdk.setChatVideoInDevices(localizedName)
    }
}

extension CallsLocalVideoRepository: MEGAChatVideoDelegate {
    func onChatVideoData(_ api: MEGAChatSdk!, chatId: UInt64, width: Int, height: Int, buffer: Data!) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
}

extension CallsLocalVideoRepository: MEGAChatRequestDelegate {
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if request.type == .changeVideoStream || request.type == .disableAudioVideoCall {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
