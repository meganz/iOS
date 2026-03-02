public protocol SensitiveDisplayPreferenceUseCaseProtocol: Sendable {
    ///  Determines whether sensitive content should be excluded.
    /// - Returns: A `Bool` indicating whether sensitive content should be excluded. It will always return `false` if the account type is invalid
    func excludeSensitives() async -> Bool
}

public struct SensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCaseProtocol {
    
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sensitiveFilteringEnabled: Bool
    
    public init(
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        sensitiveFilteringEnabled: Bool = true
    ) {
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sensitiveFilteringEnabled = sensitiveFilteringEnabled
    }
    
    public func excludeSensitives() async -> Bool {
        guard sensitiveFilteringEnabled,
              sensitiveNodeUseCase.isAccessible() else { return false }
        
        return await !contentConsumptionUserAttributeUseCase
            .fetchSensitiveAttribute().showHiddenNodes
    }
}
