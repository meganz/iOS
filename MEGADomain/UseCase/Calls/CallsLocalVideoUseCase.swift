
protocol CallsLocalVideoUseCaseProtocol {
    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func addLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallsLocalVideoCallbacksUseCaseProtocol)
    func removeLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallsLocalVideoCallbacksUseCaseProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String)
}

protocol CallsLocalVideoCallbacksUseCaseProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data!)
    func localVideoChangedCameraPosition()
}

final class CallsLocalVideoUseCase: NSObject, CallsLocalVideoUseCaseProtocol {
    
    private let repository: CallsLocalVideoRepositoryProtocol
    private var localVideoCallbacksDelegate: CallsLocalVideoCallbacksUseCaseProtocol?
    
    init(repository: CallsLocalVideoRepositoryProtocol) {
        self.repository = repository
    }
    
    func enableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, completion: completion)
    }
    
    func disableLocalVideo(for chatId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, completion: completion)
    }
    
    func addLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallsLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = callbacksDelegate
        repository.addLocalVideo(for: chatId, localVideoListener: self)
    }
    
    func removeLocalVideo(for chatId: MEGAHandle, callbacksDelegate: CallsLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = nil
        repository.removeLocalVideo(for: chatId, localVideoListener: self)
    }
    
    func videoDeviceSelected() -> String? {
        repository.videoDeviceSelected()
    }
    
    func selectCamera(withLocalizedName localizedName: String) {
        repository.selectCamera(withLocalizedName: localizedName)
    }
}

extension CallsLocalVideoUseCase: CallsLocalVideoListenerRepositoryProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data!) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
    
    func localVideoChangedCameraPosition() {
        localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
    }
}
