import Foundation

public struct SetChangeTypeEntity: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let new      = SetChangeTypeEntity(rawValue: 1 << 0)
    public static let name     = SetChangeTypeEntity(rawValue: 1 << 1)
    public static let cover    = SetChangeTypeEntity(rawValue: 1 << 2)
    public static let removed  = SetChangeTypeEntity(rawValue: 1 << 3)
    public static let exported = SetChangeTypeEntity(rawValue: 1 << 4)
}
