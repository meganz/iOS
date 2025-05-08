import MEGAAccountManagement
import MEGAAppPresentation
import MEGADomain
import MEGAStoreKit

extension DIContainer {
    static var externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol {
        ExternalPurchaseUseCase(
            storeRepository: LegacyStoreKitRepository(),
            sessionTransferRepository: SessionTransferRepository(sdk: .sharedSdk),
            remoteFeatureFlagEnabled: {
                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(
                    for: .appleExternalPurchase
                )
            }
        )
    }
}
