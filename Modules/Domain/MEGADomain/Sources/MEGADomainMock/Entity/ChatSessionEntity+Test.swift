import Foundation
import MEGADomain

public extension ChatSessionEntity {
    /// Init method with default values (0, false, nil, [], ...)
    init(
        statusType: StatusType? = .invalid,
        termCode: ChatSessionTermCode? = .invalid,
        hasAudio: Bool = false,
        hasVideo: Bool = false,
        peerId: HandleEntity = .invalid,
        clientId: HandleEntity = .invalid,
        audioDetected: Bool = false,
        isOnHold: Bool = false,
        changes: Int = 0,
        isHighResolution: Bool = false,
        isLowResolution: Bool = false,
        canReceiveVideoHiRes: Bool = false,
        canReceiveVideoLowRes: Bool = false,
        hasCamera: Bool = false,
        isLowResCamera: Bool = false,
        isHiResCamera: Bool = false,
        hasScreenShare: Bool = false,
        isLowResScreenShare: Bool = false,
        isHiResScreenShare: Bool = false,
        isTesting: Bool = true
    ) {
        self.init(
            statusType: statusType,
            termCode: termCode,
            hasAudio: hasAudio,
            hasVideo: hasVideo,
            peerId: peerId,
            clientId: clientId,
            audioDetected: audioDetected,
            isOnHold: isOnHold,
            changes: changes,
            isHighResolution: isHighResolution,
            isLowResolution: isLowResolution,
            canReceiveVideoHiRes: canReceiveVideoHiRes,
            canReceiveVideoLowRes: canReceiveVideoLowRes,
            hasCamera: hasCamera,
            isLowResCamera: isLowResCamera,
            isHiResCamera: isHiResCamera,
            hasScreenShare: hasScreenShare,
            isLowResScreenShare: isLowResScreenShare,
            isHiResScreenShare: isHiResScreenShare
        )
    }
}
