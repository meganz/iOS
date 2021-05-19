enum CallsErrorEntity: Error {
    case generic
    case chatNotConnected
    case tooManyParticipants
    case chatLocalVideoNotEnabled
    case chatLocalVideoNotDisabled
    case requestResolutionVideoChange
    case stopHighResolutionVideo
    case stopLowResolutionVideo
}
