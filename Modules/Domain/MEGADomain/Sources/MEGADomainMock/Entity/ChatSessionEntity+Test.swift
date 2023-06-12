import Foundation
import MEGADomain

public extension ChatSessionEntity {
    /// Init method with default values (0, false, nil, [], ...)
    init(statusType: StatusType = .invalid,
         hasAudio: Bool = false,
         hasVideo: Bool = false,
         peerId: HandleEntity = .invalid,
         clientId: HandleEntity = .invalid,
         changes: Int = 0,
         isHighResolution: Bool = false,
         isLowResolution: Bool = false) {
        self.init(statusType: statusType, termCode: .invalid, hasAudio: hasAudio, hasVideo: hasVideo, peerId: peerId, clientId: clientId, audioDetected: false, isOnHold: false, changes: changes, isHighResolution: isHighResolution, isLowResolution: isLowResolution, canReceiveVideoHiRes: false, canReceiveVideoLowRes: false)
    }
}
