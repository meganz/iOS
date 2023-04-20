import MEGADomain

extension NodeAccessTypeEntity {
    init?(shareAccess: MEGAShareType) {
        self.init(rawValue: shareAccess.rawValue)
    }
    
    func toShareAccessLevel() -> ShareAccessLevelEntity {
        switch self {
        case .read:
            return .read
        case .readWrite:
            return .readWrite
        case .full:
            return .full
        case .owner:
            return .owner
        case .unknown:
            return .unknown
        }
    }
}
