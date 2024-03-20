import Foundation
import MEGADomain
import MEGAPresentation

struct NodeActionViewModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    var accountType: AccountTypeEntity? {
        accountUseCase.currentAccountDetails?.proLevel
    }
    
    init(accountUseCase: some AccountUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.accountUseCase = accountUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    func containsOnlySensitiveNodes(_ nodes: [NodeEntity]) -> Bool? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return nil
        }
        return nodes.notContains { !$0.isMarkedSensitive }
    }
}
