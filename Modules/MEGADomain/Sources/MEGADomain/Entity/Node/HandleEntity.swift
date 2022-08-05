public typealias Base64HandleEntity = String

public typealias HandleEntity = UInt64

public extension HandleEntity {
    static let invalid = ~UInt64.zero
}
