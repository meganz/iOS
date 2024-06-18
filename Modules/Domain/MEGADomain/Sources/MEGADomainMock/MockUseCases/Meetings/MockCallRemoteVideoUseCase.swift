import MEGADomain

public final class MockCallRemoteVideoUseCase: CallRemoteVideoUseCaseProtocol {
    public var addRemoteVideoListener_CalledTimes = 0
    public var disableAllRemoteVideos_CalledTimes = 0
    public var enableRemoteVideo_CalledTimes = 0
    private var disableRemoteVideo_CalledTimes = 0
    public var requestHighResolutionVideo_calledTimes = 0
    public var requestLowResolutionVideo_calledTimes = 0
    private var stopHighResolutionVideo_calledTimes = 0
    public var stopLowResolutionVideo_calledTimes = 0
    
    private let requestHighResolutionVideoCompletion: Result<Void, CallErrorEntity>
    private let stopHighResolutionVideoCompletion: Result<Void, CallErrorEntity>
    private let requestLowResolutionVideoCompletion: Result<Void, CallErrorEntity>
    private let stopLowResolutionVideoCompletion: Result<Void, CallErrorEntity>
    private let isReceivingBothHighAndLowResVideo: Bool
    private let isNotReceivingBothBothHighAndLowResVideo: Bool
    private let isOnlyReceivingHighResVideo: Bool
    private let isOnlyReceivingLowResVideo: Bool
    
    public init(
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
    
    public func addRemoteVideoListener(_ remoteVideoListener: some CallRemoteVideoListenerUseCaseProtocol) {
        addRemoteVideoListener_CalledTimes += 1
    }
    
    public func enableRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        enableRemoteVideo_CalledTimes += 1
    }
    
    public func disableRemoteVideo(for participant: CallParticipantEntity, isHiRes: Bool) {
        disableRemoteVideo_CalledTimes += 1
    }
    
    public func disableAllRemoteVideos() {
        disableAllRemoteVideos_CalledTimes += 1
    }
    
    public func requestHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        requestHighResolutionVideo_calledTimes += 1
        completion?(requestHighResolutionVideoCompletion)
    }
    
    public func requestLowResolutionVideos(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        requestLowResolutionVideo_calledTimes += 1
        completion?(requestLowResolutionVideoCompletion)
    }
    
    public func stopHighResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        stopHighResolutionVideo_calledTimes += 1
        completion?(stopHighResolutionVideoCompletion)
    }
    
    public func stopLowResolutionVideo(for chatId: HandleEntity, clientId: HandleEntity, completion: ResolutionVideoChangeCompletion?) {
        stopLowResolutionVideo_calledTimes += 1
        completion?(stopLowResolutionVideoCompletion)
    }
    
    public func isReceivingBothHighAndLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isReceivingBothHighAndLowResVideo
    }
    
    public func isNotReceivingBothBothHighAndLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isNotReceivingBothBothHighAndLowResVideo
    }
    
    public func isOnlyReceivingHighResVideo(for participant: CallParticipantEntity) -> Bool {
        isOnlyReceivingHighResVideo
    }
    
    public func isOnlyReceivingLowResVideo(for participant: CallParticipantEntity) -> Bool {
        isOnlyReceivingLowResVideo
    }
}
