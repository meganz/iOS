public struct ChangeTypeEntity: OptionSet, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let removed          = ChangeTypeEntity(rawValue: 1 << 0) // 1 0x01
    public static let attributes       = ChangeTypeEntity(rawValue: 1 << 1) // 2 0x02
    public static let owner            = ChangeTypeEntity(rawValue: 1 << 2) // 4 0x04
    public static let timestamp        = ChangeTypeEntity(rawValue: 1 << 3) // 8 0x08
    public static let fileAttributes   = ChangeTypeEntity(rawValue: 1 << 4) // 16 0x10
    public static let inShare          = ChangeTypeEntity(rawValue: 1 << 5) // 32 0x20
    public static let outShare         = ChangeTypeEntity(rawValue: 1 << 6) // 64 0x40
    public static let parent           = ChangeTypeEntity(rawValue: 1 << 7) // 128 0x80
    public static let pendingShare     = ChangeTypeEntity(rawValue: 1 << 8) // 256 0x100
    public static let publicLink       = ChangeTypeEntity(rawValue: 1 << 9) // 512 0x200
    public static let new              = ChangeTypeEntity(rawValue: 1 << 10) // 1024 0x400
    public static let name             = ChangeTypeEntity(rawValue: 1 << 11) // 2048 0x800
    public static let favourite        = ChangeTypeEntity(rawValue: 1 << 12) // 4096 0x1000
    public static let counter          = ChangeTypeEntity(rawValue: 1 << 13) // 8192 0x2000
    public static let sensitive        = ChangeTypeEntity(rawValue: 1 << 14) // 16384 0x4000
    public static let pwd              = ChangeTypeEntity(rawValue: 1 << 15) // 32768 0x8000
    public static let description      = ChangeTypeEntity(rawValue: 1 << 15) // 65536 0x10000
    public static let tags             = ChangeTypeEntity(rawValue: 1 << 17) // 131072 0x20000

}
