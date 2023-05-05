import Foundation

public struct SetElementChangeTypeEntity: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let new      = SetElementChangeTypeEntity(rawValue: 1 << 0)
    public static let name     = SetElementChangeTypeEntity(rawValue: 1 << 1)
    public static let order    = SetElementChangeTypeEntity(rawValue: 1 << 2)
    public static let removed  = SetElementChangeTypeEntity(rawValue: 1 << 3)
}
