import MEGAAppPresentation
import MEGAStoreKit

extension DIContainer {
    static var externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol {
        ExternalPurchaseUseCase(
            storeRepository: LegacyStoreKitRepository(),
            remoteFeatureFlagEnabled: {
                // swiftlint:disable:next todo
                true // TODO: Remove before push
//                DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .appleExternalPurchase)
            }
        )
    }
}
