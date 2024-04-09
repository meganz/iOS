import Foundation

public struct SensitiveNodesUserAttributeEntity: Sendable, Equatable {
    public let onboarded: Bool
    public let showHiddenNodes: Bool
    
    public init(onboarded: Bool, showHiddenNodes: Bool) {
        self.onboarded = onboarded
        self.showHiddenNodes = showHiddenNodes
    }
}
