import MEGAChatSdk

public final class MockMEGAChatSession: MEGAChatSession {
    private let _status: MEGAChatSessionStatus
    private let _termCode: MEGAChatSessionTermCode
    private let _hasAudio: Bool
    private let _hasVideo: Bool
    private let _peerId: UInt64
    private let _clientId: UInt64
    private let _audioDetected: Bool
    private let _isOnHold: Bool
    private let _changes: Int
    private let _isHighResVideo: Bool
    private let _isLowResVideo: Bool
    private let _canReceiveVideoHiRes: Bool
    private let _canReceiveVideoLowRes: Bool
    private let _hasCamera: Bool
    private let _isLowResCamera: Bool
    private let _isHiResCamera: Bool
    private let _hasScreenShare: Bool
    private let _isLowResScreenShare: Bool
    private let _isHiResScreenShare: Bool
    
    public init(
        status: MEGAChatSessionStatus = .invalid,
        termCode: MEGAChatSessionTermCode = .invalid,
        hasAudio: Bool = false,
        hasVideo: Bool = false,
        peerId: UInt64 = 1,
        clientId: UInt64 = 1,
        audioDetected: Bool = false,
        isOnHold: Bool = false,
        changes: Int = 0,
        isHighResVideo: Bool = false,
        isLowResVideo: Bool = false,
        canReceiveVideoHiRes: Bool = false,
        canReceiveVideoLowRes: Bool = false,
        hasCamera: Bool = false,
        isLowResCamera: Bool = false,
        isHiResCamera: Bool = false,
        hasScreenShare: Bool = false,
        isLowResScreenShare: Bool = false,
        isHiResScreenShare: Bool = false
    ) {
        _status = status
        _termCode = termCode
        _hasAudio = hasAudio
        _hasVideo = hasVideo
        _peerId = peerId
        _clientId = clientId
        _audioDetected = audioDetected
        _isOnHold = isOnHold
        _changes = changes
        _isHighResVideo = isHighResVideo
        _isLowResVideo = isLowResVideo
        _canReceiveVideoHiRes = canReceiveVideoHiRes
        _canReceiveVideoLowRes = canReceiveVideoLowRes
        _hasCamera = hasCamera
        _isLowResCamera = isLowResCamera
        _isHiResCamera = isHiResCamera
        _hasScreenShare = hasScreenShare
        _isLowResScreenShare = isLowResScreenShare
        _isHiResScreenShare = isHiResScreenShare
        super.init()
    }
    
    public override var status: MEGAChatSessionStatus {
        _status
    }
    
    public override var termCode: MEGAChatSessionTermCode {
        _termCode
    }
    
    public override var hasAudio: Bool {
        _hasAudio
    }
    
    public override var hasVideo: Bool {
        _hasVideo
    }
    
    public override var peerId: UInt64 {
        _peerId
    }
    
    public override var clientId: UInt64 {
        _clientId
    }
    
    public override var audioDetected: Bool {
        _audioDetected
    }
    
    public override var isOnHold: Bool {
        _isOnHold
    }
    
    public override var changes: Int {
        _changes
    }
    
    public override var isHighResVideo: Bool {
        _isHighResVideo
    }
    
    public override var isLowResVideo: Bool {
        _isLowResVideo
    }
    
    public override var canReceiveVideoHiRes: Bool {
        _canReceiveVideoHiRes
    }
    
    public override var canReceiveVideoLowRes: Bool {
        _canReceiveVideoLowRes
    }
    
    public override var hasCamera: Bool {
        _hasCamera
    }
    
    public override var isLowResCamera: Bool {
        _isLowResCamera
    }
    
    public override var isHiResCamera: Bool {
        _isHiResCamera
    }
    
    public override var hasScreenShare: Bool {
        _hasScreenShare
    }
    
    public override var isLowResScreenShare: Bool {
        _isLowResScreenShare
    }
    
    public override var isHiResScreenShare: Bool {
        _isHiResScreenShare
    }
}
