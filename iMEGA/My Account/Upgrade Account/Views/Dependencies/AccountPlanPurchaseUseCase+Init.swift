import MEGAAppPresentation
import MEGADomain

extension AccountPlanPurchaseUseCase where T: AccountPlanPurchaseRepositoryProtocol {
    init(repository: T) {
        self.init(
            repository: repository,
            useAPIPrice: { @Sendable in
                await DIContainer.externalPurchaseUseCase.shouldProvideExternalPurchase()
            }
        )
    }
}
