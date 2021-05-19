
protocol CallsRemoteVideoUseCaseProtocol {
    func addRemoteVideoListener(_ remoteVideoListener: CallsRemoteVideoListenerUseCaseProtocol)
    func enableRemoteVideo(for participant: CallParticipantEntity)
    func disableRemoteVideo(for participant: CallParticipantEntity)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void)
}

protocol CallsRemoteVideoListenerUseCaseProtocol: class {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data!)
}

final class CallsRemoteVideoUseCase: NSObject, CallsRemoteVideoUseCaseProtocol {
    
    private let repository: CallsRemoteVideoRepositoryProtocol
    private weak var remoteVideoListener: CallsRemoteVideoListenerUseCaseProtocol?

    init(repository: CallsRemoteVideoRepository) {
        self.repository = repository
    }
     
    func addRemoteVideoListener(_ remoteVideoListener: CallsRemoteVideoListenerUseCaseProtocol) {
        self.remoteVideoListener = remoteVideoListener
    }
    
    func enableRemoteVideo(for participant: CallParticipantEntity) {
        repository.enableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.videoResolution == .high, remoteVideoListener: self)
    }
    
    func disableRemoteVideo(for participant: CallParticipantEntity) {
        repository.disableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.videoResolution == .high)
    }
    
    func disableAllRemoteVideos() {
        repository.disableAllRemoteVideos()
    }
    
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.requestHighResolutionVideo(for: chatId, clientId: clientId, completion: completion)
    }

    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.stopHighResolutionVideo(for: chatId, clientIds: clientIds, completion: completion)
    }
    
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.requestLowResolutionVideos(for: chatId, clientIds: clientIds, completion: completion)
    }
    
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        repository.stopLowResolutionVideo(for: chatId, clientIds: clientIds, completion: completion)
    }
}

extension CallsRemoteVideoUseCase: CallsRemoteVideoListenerRepositoryProtocol {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data!) {
        remoteVideoListener?.remoteVideoFrameData(clientId: clientId, width: width, height: height, buffer: buffer)
    }
}
