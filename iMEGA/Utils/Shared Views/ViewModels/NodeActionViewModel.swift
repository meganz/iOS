import Foundation
import MEGADomain
import MEGAPresentation

struct NodeActionViewModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let systemGeneratedNodeUseCase: any SystemGeneratedNodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    var hasValidProOrUnexpiredBusinessAccount: Bool {
        accountUseCase.hasValidProOrUnexpiredBusinessAccount()
    }
    
    init(accountUseCase: some AccountUseCaseProtocol,
         systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.accountUseCase = accountUseCase
        self.systemGeneratedNodeUseCase = systemGeneratedNodeUseCase
        self.featureFlagProvider = featureFlagProvider
    }
    
    func containsOnlySensitiveNodes(_ nodes: [NodeEntity], isFromSharedItem: Bool) async -> Bool? {
        do {
            guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
                  isFromSharedItem == false else {
                return nil
            }
            
            // If sequence contains some sensitive nodes, Else should allow unhide action.
            guard nodes.contains(where: { $0.isMarkedSensitive == false }) else {
                return true
            }
            
            // If nodes contains a system managed node:
            return if try await systemGeneratedNodeUseCase.containsSystemGeneratedNode(nodes: nodes) {
                // If Sequence does not contain any sensitive nodes, show no action. Else should show unhide action.
                nodes.notContains(where: \.isMarkedSensitive) ? nil : true
            } else {
                false // Sequence contains at least one sensitive node, should show hide action.
            }
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] containsOnlySensitiveNodes cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] Error determining node sensitivity. Error: \(error)")
        }
        return nil
    }
}
