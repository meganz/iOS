public enum CallErrorEntity: Error {
    case generic
    case tooManyParticipants
    case chatLocalVideoNotEnabled
    case chatLocalVideoNotDisabled
    case requestResolutionVideoChange
    case stopHighResolutionVideo
    case stopLowResolutionVideo
}
