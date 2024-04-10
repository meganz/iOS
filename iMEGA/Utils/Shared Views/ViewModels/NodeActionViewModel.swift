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
    
    func containsOnlySensitiveNodes(_ nodes: [NodeEntity], isFromSharedItem: Bool) -> Bool? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              isFromSharedItem == false else {
            return nil
        }
        return nodes.notContains { !$0.isMarkedSensitive }
    }
}
