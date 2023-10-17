import Foundation

public protocol CallLocalVideoUseCaseProtocol {
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, any Error>) -> Void)
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
}

public protocol CallLocalVideoCallbacksUseCaseProtocol: AnyObject {
    func localVideoFrameData(width: Int, height: Int, buffer: Data)
    func localVideoChangedCameraPosition()
}

public final class CallLocalVideoUseCase<T: CallLocalVideoRepositoryProtocol>: NSObject, CallLocalVideoUseCaseProtocol {
    
    private let repository: T
    private weak var localVideoCallbacksDelegate: (any CallLocalVideoCallbacksUseCaseProtocol)?
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, completion: completion)
    }
    
    public func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, completion: completion)
    }
    
    public func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = callbacksDelegate
        repository.addLocalVideo(for: chatId, localVideoListener: self)
    }
    
    public func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        localVideoCallbacksDelegate = nil
        repository.removeLocalVideo(for: chatId, localVideoListener: self)
    }
    
    public func videoDeviceSelected() -> String? {
        repository.videoDeviceSelected()
    }
    
    public func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        repository.selectCamera(withLocalizedName: localizedName, completion: completion)
    }
    
    public func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.openVideoDevice(completion: completion)
    }
    
    public func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.releaseVideoDevice(completion: completion)
    }
}

extension CallLocalVideoUseCase: CallLocalVideoListenerRepositoryProtocol {
    public func localVideoFrameData(width: Int, height: Int, buffer: Data) {
        localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
    }
    
    public func localVideoChangedCameraPosition() {
        localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
    }
}
