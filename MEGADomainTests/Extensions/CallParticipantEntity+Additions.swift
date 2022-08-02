import Foundation
@testable import MEGA

extension CallParticipantEntity {
    ///Init method with default values (0, false, nil, [], ...)
    convenience init(chatId: HandleEntity = MEGAInvalidHandle,
         participantId: HandleEntity = MEGAInvalidHandle,
         clientId: HandleEntity = MEGAInvalidHandle,
         email: String = "test@email.com",
         isModerator: Bool = false,
         isInContactList: Bool = false,
         video: CallParticipantAudioVideoFlag = .unknown,
         audio: CallParticipantAudioVideoFlag = .unknown,
         isVideoHiRes: Bool = false,
         isVideoLowRes: Bool = false,
         canReceiveVideoHiRes: Bool = false,
         canReceiveVideoLowRes: Bool = false) {
        self.init(chatId: chatId, participantId: participantId, clientId: clientId, networkQuality: 1, email: email, isModerator: isModerator, isInContactList: isInContactList, video: video, audio: audio, isVideoHiRes: isVideoHiRes, isVideoLowRes: isVideoLowRes, canReceiveVideoHiRes: canReceiveVideoHiRes, canReceiveVideoLowRes: canReceiveVideoLowRes, name: "")
    }
}
