import Foundation

public protocol ReuseIdentifiable {
    static var reuseID: String { get }
}

public extension ReuseIdentifiable {
    static var reuseID: String { String(describing: Self.self) }
}
