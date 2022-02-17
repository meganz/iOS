struct ChangeTypeEntity: OptionSet {
    let rawValue: UInt
    
    static let removed          = ChangeTypeEntity(rawValue: 1 << 0)
    static let attributes       = ChangeTypeEntity(rawValue: 1 << 1)
    static let owner            = ChangeTypeEntity(rawValue: 1 << 2)
    static let timestamp        = ChangeTypeEntity(rawValue: 1 << 3)
    static let fileAttributes   = ChangeTypeEntity(rawValue: 1 << 4)
    static let inShare          = ChangeTypeEntity(rawValue: 1 << 5)
    static let outShare         = ChangeTypeEntity(rawValue: 1 << 6)
    static let parent           = ChangeTypeEntity(rawValue: 1 << 7)
    static let pendingShare     = ChangeTypeEntity(rawValue: 1 << 8)
    static let publicLink       = ChangeTypeEntity(rawValue: 1 << 9)
    static let new              = ChangeTypeEntity(rawValue: 1 << 10)
    static let name             = ChangeTypeEntity(rawValue: 1 << 11)
    static let favourite        = ChangeTypeEntity(rawValue: 1 << 12)
    
}
