
enum CallParticipantAudioVideoFlag {
    case off
    case on
    case unknown
}

final class CallParticipantEntity: Equatable {
    let chatId: MEGAHandle
    let participantId: MEGAHandle
    let clientId: MEGAHandle
    var networkQuality: Int
    var name: String?
    var video: CallParticipantAudioVideoFlag = .unknown
    var audio: CallParticipantAudioVideoFlag = .unknown
    
    init(chatId: MEGAHandle, participantId: MEGAHandle, clientId: MEGAHandle, networkQuality: Int, name: String?) {
        self.chatId = chatId
        self.participantId = participantId
        self.clientId = clientId
        self.networkQuality = networkQuality
        self.name = name
    }
    
    static func == (lhs: CallParticipantEntity, rhs: CallParticipantEntity) -> Bool {
        lhs.participantId == rhs.participantId && lhs.clientId == rhs.clientId
    }
}

