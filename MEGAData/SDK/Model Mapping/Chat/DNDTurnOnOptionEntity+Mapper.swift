import MEGADomain

extension DNDTurnOnOptionEntity {
    func toDNDTurnOnOption() -> DNDTurnOnOption {
        switch self {
        case .thirtyMinutes:
            return .thirtyMinutes
        case .oneHour:
            return .oneHour
        case .sixHours:
            return .sixHours
        case .twentyFourHours:
            return .twentyFourHours
        case .morningEightAM:
            return .morningEightAM
        case .forever:
            return .forever
        }
    }
}
