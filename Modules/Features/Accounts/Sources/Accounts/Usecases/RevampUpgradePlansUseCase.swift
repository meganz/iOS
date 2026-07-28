import MEGADomain
public protocol RevampUpgradePlansUseCaseProtocol: Sendable {
    /// Available account plans with their introductory and promotional offers merged in.
    func plans() async -> [PlanEntity]
    /// The user's current account details, refreshed when not already cached.
    func currentAccountDetails() async throws -> AccountDetailsEntity
}

public struct RevampUpgradePlansUseCase: RevampUpgradePlansUseCaseProtocol {
    private let productsUseCase: any AccountPlanProductsUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol

    public init(
        productsUseCase: some AccountPlanProductsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.productsUseCase = productsUseCase
        self.accountUseCase = accountUseCase
    }

    public func plans() async -> [PlanEntity] {
        await productsUseCase.availablePlans()
    }

    public func currentAccountDetails() async throws -> AccountDetailsEntity {
        if let details = accountUseCase.currentAccountDetails {
            return details
        }
        return try await accountUseCase.refreshCurrentAccountDetails()
    }
}
