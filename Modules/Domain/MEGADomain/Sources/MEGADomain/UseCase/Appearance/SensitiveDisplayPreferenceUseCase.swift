
public protocol SensitiveDisplayPreferenceUseCaseProtocol: Sendable {
    ///  Determines whether sensitive content should be excluded.
    /// - Returns: A `Bool` indicating whether sensitive content should be excluded. It will always return `false` if the account type is invalid
    func excludeSensitives() async -> Bool
}

public struct SensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool
    
    public init(
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool
    ) {
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    public func excludeSensitives() async -> Bool {
        guard hiddenNodesFeatureFlagEnabled(),
              sensitiveNodeUseCase.isAccessible() else { return false }
        
        return await !contentConsumptionUserAttributeUseCase
            .fetchSensitiveAttribute().showHiddenNodes
    }
}
