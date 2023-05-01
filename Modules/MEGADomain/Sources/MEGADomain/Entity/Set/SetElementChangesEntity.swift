import Foundation

public struct SetElementChangesEntity: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let new      = SetElementChangesEntity(rawValue: 1 << 0)
    public static let name     = SetElementChangesEntity(rawValue: 1 << 1)
    public static let order    = SetElementChangesEntity(rawValue: 1 << 2)
    public static let removed  = SetElementChangesEntity(rawValue: 1 << 3)
}
