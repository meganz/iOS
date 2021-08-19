
typealias ResolutionVideoChangeCompletion = (Result<Void, CallErrorEntity>) -> Void

protocol CallRemoteVideoUseCaseProtocol {
    func addRemoteVideoListener(_ remoteVideoListener: CallRemoteVideoListenerUseCaseProtocol)
    func enableRemoteVideo(for participant: CallParticipantEntity)
    func disableRemoteVideo(for participant: CallParticipantEntity)
    func disableAllRemoteVideos()
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?)
    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?)
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?)
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?)
}

protocol CallRemoteVideoListenerUseCaseProtocol: AnyObject {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data)
}

final class CallRemoteVideoUseCase: NSObject, CallRemoteVideoUseCaseProtocol {
    
    private let repository: CallRemoteVideoRepositoryProtocol
    private weak var remoteVideoListener: CallRemoteVideoListenerUseCaseProtocol?

    init(repository: CallRemoteVideoRepository) {
        self.repository = repository
    }
     
    func addRemoteVideoListener(_ remoteVideoListener: CallRemoteVideoListenerUseCaseProtocol) {
        self.remoteVideoListener = remoteVideoListener
    }
    
    func enableRemoteVideo(for participant: CallParticipantEntity) {
        repository.enableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.canReceiveVideoHiRes, remoteVideoListener: self)
    }
    
    func disableRemoteVideo(for participant: CallParticipantEntity) {
        repository.disableRemoteVideo(for: participant.chatId, clientId: participant.clientId, hiRes: participant.canReceiveVideoHiRes)
    }
    
    func disableAllRemoteVideos() {
        repository.disableAllRemoteVideos()
    }
    
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: ResolutionVideoChangeCompletion?) {
        repository.requestHighResolutionVideo(for: chatId, clientId: clientId, completion: completion)
    }

    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?) {
        repository.stopHighResolutionVideo(for: chatId, clientIds: clientIds, completion: completion)
    }
    
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?) {
        repository.requestLowResolutionVideos(for: chatId, clientIds: clientIds, completion: completion)
    }
    
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: ResolutionVideoChangeCompletion?) {
        repository.stopLowResolutionVideo(for: chatId, clientIds: clientIds, completion: completion)
    }
}

extension CallRemoteVideoUseCase: CallRemoteVideoListenerRepositoryProtocol {
    func remoteVideoFrameData(clientId: MEGAHandle, width: Int, height: Int, buffer: Data) {
        remoteVideoListener?.remoteVideoFrameData(clientId: clientId, width: width, height: height, buffer: buffer)
    }
}
