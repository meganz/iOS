import MEGADomain

protocol CallLocalVideoUseCaseProtocol {
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionErrorEntity>) -> Void)
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
}

protocol CallLocalVideoCallbacksUseCaseProtocol: AnyObject {
    func localVideoFrameData(width: Int, height: Int, buffer: Data)
    func localVideoChangedCameraPosition()
}

final class CallLocalVideoUseCase<T: CallLocalVideoRepositoryProtocol>: NSObject, CallLocalVideoUseCaseProtocol {
    
    private let repository: T
    private weak var localVideoCallbacksDelegate: (any CallLocalVideoCallbacksUseCaseProtocol)?
    
    init(repository: T) {
        self.repository = repository
    }
    
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, completion: completion)
    }
    
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, completion: completion)
    }
    
    func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = callbacksDelegate
        repository.addLocalVideo(for: chatId, localVideoListener: self)
    }
    
    func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = nil
        repository.removeLocalVideo(for: chatId, localVideoListener: self)
    }
    
    func videoDeviceSelected() -> String? {
        repository.videoDeviceSelected()
    }
    
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, CameraSelectionErrorEntity>) -> Void) {
        repository.selectCamera(withLocalizedName: localizedName, completion: completion)
    }
    
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.openVideoDevice(completion: completion)
    }
    
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.releaseVideoDevice(completion: completion)
    }
}

extension CallLocalVideoUseCase: CallLocalVideoListenerRepositoryProtocol {
    func localVideoFrameData(width: Int, height: Int, buffer: Data) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
    
    func localVideoChangedCameraPosition() {
        localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
    }
}
