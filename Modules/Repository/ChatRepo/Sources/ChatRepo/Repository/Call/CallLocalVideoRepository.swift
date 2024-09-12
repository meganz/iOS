import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class CallLocalVideoRepository: NSObject, CallLocalVideoRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: CallLocalVideoRepository {
        CallLocalVideoRepository(chatSdk: .sharedChatSdk)
    }
    
    private let lock = NSLock()
    private let chatSdk: MEGAChatSdk
    private weak var localVideoCallbacksDelegate: (any CallLocalVideoListenerRepositoryProtocol)?

    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func enableLocalVideo(for chatId: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.enableVideo(forChat: chatId, delegate: ChatRequestDelegate(completion: { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }))
        }
    }
    
    public func disableLocalVideo(for chatId: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.disableVideo(forChat: chatId, delegate: ChatRequestDelegate(completion: { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }))
        }
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
        lock.withLock {
            localVideoCallbacksDelegate = localVideoListener
        }
    }
    
    public func removeLocalVideo(for chatId: HandleEntity, localVideoListener: some CallLocalVideoListenerRepositoryProtocol) {
        chatSdk.removeChatLocalVideo(chatId, delegate: self)
        chatSdk.remove(self)
        lock.withLock {
            localVideoCallbacksDelegate = nil
        }
    }
    
    public func videoDeviceSelected() -> String? {
        chatSdk.videoDeviceSelected()
    }
    
    public func selectCamera(withLocalizedName localizedName: String) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.setChatVideoInDevices(localizedName, delegate: ChatRequestDelegate(completion: { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }))
        }
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
        lock.withLock {
            localVideoCallbacksDelegate?.localVideoFrameData(width: width, height: height, buffer: buffer)
        }
    }
}

extension CallLocalVideoRepository: MEGAChatRequestDelegate {
    public func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        guard request.type == .changeVideoStream else { return }
        lock.withLock {
            localVideoCallbacksDelegate?.localVideoChangedCameraPosition()
        }
    }
}
