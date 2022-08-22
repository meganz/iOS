import MEGADomain

extension NodeAccessTypeEntity {
    init?(shareAccess: MEGAShareType) {
        self.init(rawValue: shareAccess.rawValue)
    }
}
