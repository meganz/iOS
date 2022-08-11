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
