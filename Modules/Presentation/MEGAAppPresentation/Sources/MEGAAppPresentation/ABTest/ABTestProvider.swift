import MEGAAppSDKRepo
import MEGADomain

public protocol ABTestProviderProtocol: Sendable {
    func abTestVariant(for: ABTestFlagKey) async -> ABTestVariant
}

public extension ABTestProviderProtocol {
    /// Check if the AB flag is enabled
    /// - Parameter key: ABTestFlagKey to check if its enabled
    /// - Returns: True if the flag is enabled, else false
    /// - Important: This should only be used if it contains variant `baseline` and `variantA`.
    ///  Use `abTestVariant(for:)` instead if `variantB` needs to be considered
    func isEnabled(for key: ABTestFlagKey) async -> Bool {
        await abTestVariant(for: key) == .variantA
    }
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
