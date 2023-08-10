import Combine
import Foundation

public typealias ResolutionVideoChangeCompletion = (Result<Void, CallErrorEntity>) -> Void

public protocol CallRemoteVideoUseCaseProtocol {
    func addRemoteVideoListener(_ remoteVideoListener: some CallRemoteVideoListenerUseCaseProtocol)
    func enableRemoteVideo(for participant: CallParticipantEntity)
    func disableRemoteVideo(for participant: CallParticipantEntity)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
}

public protocol CallRemoteVideoListenerUseCaseProtocol: AnyObject {
    func remoteVideoFrameData(clientId: HandleEntity, width: Int, height: Int, buffer: Data)
}

public final class CallRemoteVideoUseCase<T: CallRemoteVideoRepositoryProtocol>: CallRemoteVideoUseCaseProtocol {
    enum VideoRequestType {
        case enableVideo(CallParticipantEntity)
        case disableVideo(CallParticipantEntity)
        case requestHighResolutionVideo(chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
        case stopHighResolutionVideo(chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
        case requestLowResolutionVideos(chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
        case stopLowResolutionVideo(chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?)
    }
    
    private let repository: T
    private weak var remoteVideoListener: (any CallRemoteVideoListenerUseCaseProtocol)?
    
    private let videoRequestSubject = PassthroughSubject<VideoRequestType, Never>()
    private let videoReqeustSerialQueue = DispatchQueue(label: "RemoteVideoOperationQueue", qos: .userInitiated)
    private var subscriptions = Set<AnyCancellable>()

    public init(repository: T) {
        self.repository = repository
        
        videoRequestSubject
            .buffer(size: .max, prefetch: .byRequest, whenFull: .dropOldest)
            .flatMap(maxPublishers: .max(1)) { [weak self] in
                Just($0)
                    .delay(for: .seconds(0.03), scheduler: self?.videoReqeustSerialQueue ?? DispatchQueue.global())
            }
            .sink { [weak self] in
                self?.requestVideo(for: $0)
            }
            .store(in: &subscriptions)
    }
    
    private func requestVideo(for type: VideoRequestType) {
        switch type {
        case let .enableVideo(participant):
            repository.enableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.canReceiveVideoHiRes, remoteVideoListener: self)
        case let .disableVideo(participant):
            repository.disableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.canReceiveVideoHiRes)
        case let .requestHighResolutionVideo(chatId, clientId, completion):
            repository.requestHighResolutionVideo(for: chatId, clientId: clientId, completion: completion)
        case let .stopHighResolutionVideo(chatId, clientId, completion):
            repository.stopHighResolutionVideo(for: chatId, clientId: clientId, completion: completion)
        case let .requestLowResolutionVideos(chatId, clientId, completion):
            repository.requestLowResolutionVideos(for: chatId, clientId: clientId, completion: completion)
        case let .stopLowResolutionVideo(chatId, clientId, completion):
            repository.stopLowResolutionVideo(for: chatId, clientId: clientId, completion: completion)
        }
    }
     
    public func addRemoteVideoListener(_ remoteVideoListener: some CallRemoteVideoListenerUseCaseProtocol) {
        self.remoteVideoListener = remoteVideoListener
    }
    
    public func enableRemoteVideo(for participant: CallParticipantEntity) {
        videoRequestSubject.send(.enableVideo(participant))
    }
    
    public func disableRemoteVideo(for participant: CallParticipantEntity) {
        videoRequestSubject.send(.disableVideo(participant))
    }
    
    public func disableAllRemoteVideos() {
        repository.disableAllRemoteVideos()
    }
    
    public func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        videoRequestSubject.send(.requestHighResolutionVideo(chatId: chatId, clientId: clientId, completion: completion))
    }

    public func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        videoRequestSubject.send(.stopHighResolutionVideo(chatId: chatId, clientId: clientId, completion: completion))
    }
    
    public func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        videoRequestSubject.send(.requestLowResolutionVideos(chatId: chatId, clientId: clientId, completion: completion))
    }
    
    public func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        videoRequestSubject.send(.stopLowResolutionVideo(chatId: chatId, clientId: clientId, completion: completion))
    }
}

extension CallRemoteVideoUseCase: CallRemoteVideoListenerRepositoryProtocol {
    public func remoteVideoFrameData(clientId: HandleEntity, width: Int, height: Int, buffer: Data) {
        remoteVideoListener?.remoteVideoFrameData(clientId: clientId, width: width, height: height, buffer: buffer)
    }
}
