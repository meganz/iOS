
public struct StartCallEntity {
    public let meetingName: String
    public let enableVideo: Bool
    public let enableAudio: Bool
    public let speakRequest: Bool
    public let waitingRoom: Bool
    public let allowNonHostToAddParticipants: Bool
    
    public init(meetingName: String, enableVideo: Bool, enableAudio: Bool, speakRequest: Bool, waitingRoom: Bool, allowNonHostToAddParticipants: Bool) {
        self.meetingName = meetingName
        self.enableVideo = enableVideo
        self.enableAudio = enableAudio
        self.speakRequest = speakRequest
        self.waitingRoom = waitingRoom
        self.allowNonHostToAddParticipants = allowNonHostToAddParticipants
    }
}
