import Foundation

public struct SetChangesEntity: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let new      = SetChangesEntity(rawValue: 1 << 0)
    public static let name     = SetChangesEntity(rawValue: 1 << 1)
    public static let cover    = SetChangesEntity(rawValue: 1 << 2)
    public static let removed  = SetChangesEntity(rawValue: 1 << 3)
    public static let exported = SetChangesEntity(rawValue: 1 << 4)
}
