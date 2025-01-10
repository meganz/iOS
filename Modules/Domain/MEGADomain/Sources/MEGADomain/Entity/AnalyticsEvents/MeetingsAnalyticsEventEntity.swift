public enum MeetingsAnalyticsEventEntity: Sendable {
    case endCallForAll
    case endCallInNoParticipantsPopup
    case stayOnCallInNoParticipantsPopup
    case enableCallSoundNotifications
    case disableCallSoundNotifications
    case endCallWhenEmptyCallTimeout
}
