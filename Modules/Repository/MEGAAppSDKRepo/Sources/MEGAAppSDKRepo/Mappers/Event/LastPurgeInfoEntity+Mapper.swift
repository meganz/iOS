import MEGADomain

extension LastPurgeEventEntity.PurgeReason {
    init(code: Int) {
        self = switch code {
        case 4: .inactive
        default: .unknown
        }
    }
}
