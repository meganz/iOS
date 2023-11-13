@testable import MEGA
import MEGADomain

class MockCallRemoteVideoUseCase: CallRemoteVideoUseCaseProtocol {
    var addRemoteVideoListener_CalledTimes = 0
    var disableAllRemoteVideos_CalledTimes = 0
    var enableRemoteVideo_CalledTimes = 0
    var disableRemoteVideo_CalledTimes = 0
    var requestHighResolutionVideo_calledTimes = 0
    var requestLowResolutionVideo_calledTimes = 0
    var stopHighResolutionVideo_calledTimes = 0
    var stopLowResolutionVideo_calledTimes = 0
    
    var requestHighResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    var stopHighResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    var requestLowResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    var stopLowResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic)
    var isReceivingBothHighAndLowResVideo: Bool = false
    var isNotReceivingBothBothHighAndLowResVideo: Bool = false
    var isOnlyReceivingHighResVideo: Bool = false
    var isOnlyReceivingLowResVideo: Bool = false
    
    init(
        requestHighResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic),
        stopHighResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic),
        requestLowResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic),
        stopLowResolutionVideoCompletion: Result<Void, CallErrorEntity> = .failure(.generic),
        isReceivingBothHighAndLowResVideo: Bool = false,
        isNotReceivingBothBothHighAndLowResVideo: Bool = false,
        isOnlyReceivingHighResVideo: Bool = false,
        isOnlyReceivingLowResVideo: Bool = false
    ) {
        self.requestHighResolutionVideoCompletion = requestHighResolutionVideoCompletion
        self.stopHighResolutionVideoCompletion = stopHighResolutionVideoCompletion
        self.requestLowResolutionVideoCompletion = requestLowResolutionVideoCompletion
        self.stopLowResolutionVideoCompletion = stopLowResolutionVideoCompletion
        self.isReceivingBothHighAndLowResVideo = isReceivingBothHighAndLowResVideo
        self.isNotReceivingBothBothHighAndLowResVideo = isNotReceivingBothBothHighAndLowResVideo
        self.isOnlyReceivingHighResVideo = isOnlyReceivingHighResVideo
        self.isOnlyReceivingLowResVideo = isOnlyReceivingLowResVideo
    }
    
    func addRemoteVideoListener(_ remoteVideoListener: some CallRemoteVideoListenerUseCaseProtocol) {
        addRemoteVideoListener_CalledTimes += 1
    }
    
    func enableRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        enableRemoteVideo_CalledTimes += 1
    }
    
    func disableRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        disableRemoteVideo_CalledTimes += 1
    }
    
    func disableAllRemoteVideos() {
        disableAllRemoteVideos_CalledTimes += 1
    }
    
    func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        requestHighResolutionVideo_calledTimes += 1
        completion?(requestHighResolutionVideoCompletion)
    }
    
    func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        requestLowResolutionVideo_calledTimes += 1
        completion?(requestLowResolutionVideoCompletion)
    }
    
    func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        stopHighResolutionVideo_calledTimes += 1
        completion?(stopHighResolutionVideoCompletion)
    }
    
    func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        stopLowResolutionVideo_calledTimes += 1
        completion?(stopLowResolutionVideoCompletion)
    }
    
    func isReceivingBothHighAndLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isReceivingBothHighAndLowResVideo
    }
    
    func isNotReceivingBothBothHighAndLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isNotReceivingBothBothHighAndLowResVideo
    }
    
    func isOnlyReceivingHighResVideo(for participant: CallParticipantEntity) -> Bool {
        isOnlyReceivingHighResVideo
    }
    
    func isOnlyReceivingLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isOnlyReceivingLowResVideo
    }
}
