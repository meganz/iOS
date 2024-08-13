public struct CreateMeetingNowEntity: Sendable {
    public let meetingName: String
    public let speakRequest: Bool
    public let waitingRoom: Bool
    public let allowNonHostToAddParticipants: Bool
    
    public init(meetingName: String, speakRequest: Bool, waitingRoom: Bool, allowNonHostToAddParticipants: Bool) {
        self.meetingName = meetingName
        self.speakRequest = speakRequest
        self.waitingRoom = waitingRoom
        self.allowNonHostToAddParticipants = allowNonHostToAddParticipants
    }
}
