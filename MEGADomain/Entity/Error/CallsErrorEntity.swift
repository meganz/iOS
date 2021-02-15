enum CallsErrorEntity: Error {
    case generic
    case chatNotConnected
    case tooManyParticipants
    case chatLocalVideoNotEnabled
    case chatLocalVideoNotDisabled
}
