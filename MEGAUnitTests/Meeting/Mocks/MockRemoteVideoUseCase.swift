@testable import MEGA

class MockCallsRemoteVideoUseCase: CallsRemoteVideoUseCaseProtocol {
    var addRemoteVideoListener_CalledTimes = 0
    var disableAllRemoteVideos_CalledTimes = 0
    var enableRemoteVideo_CalledTimes = 0
    var disableRemoteVideo_CalledTimes = 0
    var requestHighResolutionVideoCompletion: Result<Void, CallsErrorEntity> = .success(())
    var stopHighResolutionVideoCompletion: Result<Void, CallsErrorEntity> = .success(())
    var requestLowResolutionVideoCompletion: Result<Void, CallsErrorEntity> = .success(())
    var stopLowResolutionVideoCompletion: Result<Void, CallsErrorEntity> = .success(())

    func addRemoteVideoListener(_ remoteVideoListener: CallsRemoteVideoListenerUseCaseProtocol) {
        addRemoteVideoListener_CalledTimes += 1
    }
    
    func enableRemoteVideo(for participant: CallParticipantEntity) {
        enableRemoteVideo_CalledTimes += 1
    }
    
    func disableRemoteVideo(for participant: CallParticipantEntity) {
        disableRemoteVideo_CalledTimes += 1
    }
    
    func disableAllRemoteVideos() {
        disableAllRemoteVideos_CalledTimes += 1
    }
    
    func requestHighResolutionVideo(for chatId: MEGAHandle, clientId: MEGAHandle, completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        completion(requestHighResolutionVideoCompletion)
    }
    
    func stopHighResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        completion(stopHighResolutionVideoCompletion)
    }
    
    func requestLowResolutionVideos(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        completion(requestLowResolutionVideoCompletion)
    }
    
    func stopLowResolutionVideo(for chatId: MEGAHandle, clientIds: [MEGAHandle], completion: @escaping (Result<Void, CallsErrorEntity>) -> Void) {
        completion(stopLowResolutionVideoCompletion)
    }
}
