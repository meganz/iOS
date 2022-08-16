import Foundation

public typealias FeatureFlagName = String

public struct FeatureFlagEntity: Identifiable {
    public let id = UUID()
    public let name: FeatureFlagName
    public var isEnabled: Bool
    
    public init(name: FeatureFlagName, isEnabled: Bool) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

extension FeatureFlagEntity: Hashable {
    public static func == (lhs: FeatureFlagEntity, rhs: FeatureFlagEntity) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
