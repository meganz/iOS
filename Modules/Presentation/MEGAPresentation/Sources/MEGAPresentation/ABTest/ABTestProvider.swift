import MEGADomain
import MEGASDKRepo

public protocol ABTestProviderProtocol: Sendable {
    func abTestVariant(for: ABTestFlagKey) async -> ABTestVariant
}

public struct ABTestProvider: ABTestProviderProtocol {
    private var useCase: any ABTestUseCaseProtocol

    public init(useCase: some ABTestUseCaseProtocol = ABTestUseCase(repository: ABTestRepository.newRepo)) {
        self.useCase = useCase
    }
    
    public func abTestVariant(for key: ABTestFlagKey) async -> ABTestVariant {
        let abTestValue = await useCase.abTestValue(for: key.rawValue)
        return ABTestVariant(rawValue: abTestValue) ?? .baseline
    }
}
