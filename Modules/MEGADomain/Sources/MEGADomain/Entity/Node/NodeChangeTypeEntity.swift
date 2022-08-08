public struct ChangeTypeEntity: OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let removed          = ChangeTypeEntity(rawValue: 1 << 0)
    public static let attributes       = ChangeTypeEntity(rawValue: 1 << 1)
    public static let owner            = ChangeTypeEntity(rawValue: 1 << 2)
    public static let timestamp        = ChangeTypeEntity(rawValue: 1 << 3)
    public static let fileAttributes   = ChangeTypeEntity(rawValue: 1 << 4)
    public static let inShare          = ChangeTypeEntity(rawValue: 1 << 5)
    public static let outShare         = ChangeTypeEntity(rawValue: 1 << 6)
    public static let parent           = ChangeTypeEntity(rawValue: 1 << 7)
    public static let pendingShare     = ChangeTypeEntity(rawValue: 1 << 8)
    public static let publicLink       = ChangeTypeEntity(rawValue: 1 << 9)
    public static let new              = ChangeTypeEntity(rawValue: 1 << 10)
    public static let name             = ChangeTypeEntity(rawValue: 1 << 11)
    public static let favourite        = ChangeTypeEntity(rawValue: 1 << 12)
    
}
