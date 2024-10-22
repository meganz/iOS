import MEGADomain
import MEGADomainMock
import Testing

struct SensitiveDisplayPreferenceUseCaseTests {
    @Suite("Sensitive Display Preference Use Case Feature Flag Off")
    struct FeatureFlagOffTests {
        
        @Test
        func alwaysExcludesSensitives() async {
            let sut = SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
                contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(),
                hiddenNodesFeatureFlagEnabled: { false })
            
            #expect(await sut.excludeSensitives() == false)
        }
    }
    
    @Suite("Sensitive Display Preference Use Case Feature Flag On")
    struct FeatureFlagOnTests {
        
        @Test("Include sensitives when invalid account and show hidden nodes is off",
              arguments: [
                (false, false),
                (true, true)
              ])
        func includeSensitives(
            hasValidProOrUnexpiredBusinessAccount: Bool,
            showHiddenNodes: Bool
        ) async {
            let sut = makeSUT(
                hasValidProOrUnexpiredBusinessAccount: hasValidProOrUnexpiredBusinessAccount,
                showHiddenNodes: showHiddenNodes)
            
            #expect(await sut.excludeSensitives() == false)
        }
        
        @Test("Exclude sensitives when valid account and show hidden nodes is off")
        func excludeSensitivesSensitives() async {
            let sut = makeSUT(
                hasValidProOrUnexpiredBusinessAccount: true,
                showHiddenNodes: false)
            
            #expect(await sut.excludeSensitives())
        }
        
        private func makeSUT(
            hasValidProOrUnexpiredBusinessAccount: Bool,
            showHiddenNodes: Bool
        ) -> SensitiveDisplayPreferenceUseCase {
            SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: hasValidProOrUnexpiredBusinessAccount),
                contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                    sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: showHiddenNodes)),
                hiddenNodesFeatureFlagEnabled: { true }
            )
        }
    }
}
