import Foundation
import MEGASwift

public protocol CallLocalVideoUseCaseProtocol: Sendable {
    func enableLocalVideo(for chatId: HandleEntity) async throws
    func disableLocalVideo(for chatId: HandleEntity) async throws
    func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol)
    func videoDeviceSelected() -> String?
    func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, any Error>) -> Void)
    func selectCamera(withLocalizedName localizedName: String) async throws
    func openVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
    func releaseVideoDevice(completion: @escaping (Result<Void, CallErrorEntity>) -> Void)
}

public protocol CallLocalVideoCallbacksUseCaseProtocol: AnyObject {
    func localVideoFrameData(width: Int, height: Int, buffer: Data)
    func localVideoChangedCameraPosition()
}

public final class CallLocalVideoUseCase<T: CallLocalVideoRepositoryProtocol>: NSObject, CallLocalVideoUseCaseProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private let repository: T
    private weak var localVideoCallbacksDelegate: (any CallLocalVideoCallbacksUseCaseProtocol)?
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func enableLocalVideo(for chatId: HandleEntity) async throws {
        try await repository.enableLocalVideo(for: chatId)
    }
    
    public func disableLocalVideo(for chatId: HandleEntity) async throws {
        try await repository.disableLocalVideo(for: chatId)
    }
    
    public func enableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.enableLocalVideo(for: chatId, completion: completion)
    }
    
    public func disableLocalVideo(for chatId: HandleEntity, completion: @escaping (Result<Void, CallErrorEntity>) -> Void) {
        repository.disableLocalVideo(for: chatId, completion: completion)
    }
    
    public func addLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        lock.withLock {
            localVideoCallbacksDelegate = callbacksDelegate
        }
        repository.addLocalVideo(for: chatId, localVideoListener: self)
    }
    
    public func removeLocalVideo(for chatId: HandleEntity, callbacksDelegate: some CallLocalVideoCallbacksUseCaseProtocol) {
        lock.withLock {
            localVideoCallbacksDelegate = nil
        }
        repository.removeLocalVideo(for: chatId, localVideoListener: self)
    }
    
    public func videoDeviceSelected() -> String? {
        repository.videoDeviceSelected()
    }
    
    public func selectCamera(withLocalizedName localizedName: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        repository.selectCamera(withLocalizedName: localizedName, completion: completion)
    }
    
    public func selectCamera(withLocalizedName localizedName: String) async throws {
        try await repository.selectCamera(withLocalizedName: localizedName)
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
        lock.withLock {
            localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
        }
    }
    
    public func localVideoChangedCameraPosition() {
        lock.withLock {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
