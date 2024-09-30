
public protocol SensitiveDisplayPreferenceUseCaseProtocol: Sendable {
    ///  Determines whether sensitive content should be excluded.
    /// - Returns: A `Bool` indicating whether sensitive content should be excluded. It will always return `false` if the account type is invalid
    func excludeSensitives() async -> Bool
}

public struct SensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    
    private let accountUseCase: any AccountUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool
    ) {
        self.accountUseCase = accountUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    public func excludeSensitives() async -> Bool {
        guard hiddenNodesFeatureFlagEnabled(),
              accountUseCase.hasValidProOrUnexpiredBusinessAccount() else { return false }
        
        return await !contentConsumptionUserAttributeUseCase
            .fetchSensitiveAttribute().showHiddenNodes
    }
}
