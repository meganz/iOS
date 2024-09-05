import Foundation

public typealias FeatureFlagName = String

public struct FeatureFlagEntity: Sendable {
    public let name: FeatureFlagName
    public var isEnabled: Bool
    
    public init(name: FeatureFlagName, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

extension FeatureFlagEntity: Identifiable {
    public var id: FeatureFlagName { name }
}

extension FeatureFlagEntity: Hashable {
    public static func == (lhs: FeatureFlagEntity, rhs: FeatureFlagEntity) -> Bool {
        lhs.name == rhs.name && lhs.isEnabled == rhs.isEnabled
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isEnabled)
    }
}
