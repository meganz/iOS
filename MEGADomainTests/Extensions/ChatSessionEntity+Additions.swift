import Foundation
@testable import MEGA

extension ChatSessionEntity {
    ///Init method with default values (0, false, nil, [], ...)
    init(statusType: StatusType = .initial,
         hasAudio: Bool = false,
         hasVideo: Bool = false,
         peerId: UInt64 = MEGAInvalidHandle,
         clientId: UInt64 = MEGAInvalidHandle,
         changes: Int = 0,
         isHighResolution: Bool = false,
         isLowResolution: Bool = false) {
        self.init(statusType: statusType, termCode: .invalid, hasAudio: hasAudio, hasVideo: hasVideo, peerId: peerId, clientId: clientId, audioDetected: false, isOnHold: false, changes: changes, isHighResolution: isHighResolution, isLowResolution: isLowResolution, canReceiveVideoHiRes: false, canReceiveVideoLowRes: false)
    }
}
