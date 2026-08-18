import Accounts
import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import UIKit

/// Opens the promotional offer landing dialog as the app comes to the foreground.
///
/// The trigger waits a couple of seconds before evaluating anything
/// because the app may frequently and quickly switch between the foreground and background.
/// The evaluation includes refreshing pricing information, which is an expensive operation
/// because it makes requests to both our API and StoreKit.
/// The delay allows the trigger to be cancelled if the app returns to the background, reducing unnecessary pricing requests.
@MainActor
final class PromoLandingDialogLaunchPresenter {
    static let presentationDelay: Duration = .seconds(3)

    private let isFeatureEnabled: @Sendable () async -> Bool
    private let useCase: any AppOpenPromoDialogUseCaseProtocol
    private let interruptibility: any PromoDialogInterruptibilityProtocol
    private let presentDialog: @MainActor (PromotedPlanFetchResult) -> Bool
    private let delay: @Sendable () async throws -> Void
    /// The attempt this app open is making. Readable so tests can await it instead of guessing at timing;
    /// only this class starts or cancels one, hence `private(set)`.
    private(set) var attempt: Task<Void, Never>?

    init(
        isFeatureEnabled: @escaping @Sendable () async -> Bool,
        useCase: some AppOpenPromoDialogUseCaseProtocol,
        interruptibility: some PromoDialogInterruptibilityProtocol,
        presentDialog: @escaping @MainActor (PromotedPlanFetchResult) -> Bool,
        delay: @escaping @Sendable () async throws -> Void = {
            try await Task.sleep(for: PromoLandingDialogLaunchPresenter.presentationDelay)
        }
    ) {
        self.isFeatureEnabled = isFeatureEnabled
        self.useCase = useCase
        self.interruptibility = interruptibility
        self.presentDialog = presentDialog
        self.delay = delay
    }

    func triggerIfNeeded() {
        cancel()

        attempt = Task { [isFeatureEnabled, useCase, interruptibility, presentDialog, delay] in
            do {
                try await delay()

                try Task.checkCancellation()
                guard await isFeatureEnabled() else { throw SkipReason.featureDisabled }

                try Task.checkCancellation()
                guard interruptibility.canInterruptUser else { throw SkipReason.userBusyBeforeLookup }

                guard let fetchResult = try await useCase.promotedPlanToPresent() else {
                    throw SkipReason.noOfferToShow
                }

                try Task.checkCancellation()
                guard interruptibility.canInterruptUser else { throw SkipReason.userBusyAfterLookup }

                guard presentDialog(fetchResult) else { throw SkipReason.presentationRefused }

                useCase.recordDialogShown(for: fetchResult.promotedPlan)
            } catch let reason as SkipReason {
                MEGALogDebug("[PromoLandingDialog] Skipped this app open: \(reason)")
            } catch is CancellationError {
                MEGALogDebug("[PromoLandingDialog] Skipped this app open: \(SkipReason.cancelled)")
            } catch {
                MEGALogError("[PromoLandingDialog] Could not resolve the promoted plan: \(error)")
            }
        }
    }

    /// Why an app open ended without a dialog.
    private enum SkipReason: Error {
        case cancelled
        case featureDisabled
        case userBusyBeforeLookup
        case noOfferToShow
        case userBusyAfterLookup
        case presentationRefused
    }

    func cancel() {
        attempt?.cancel()
        attempt = nil
    }
}

// MARK: - Production instance
extension PromoLandingDialogLaunchPresenter {
    /// One presenter for the process, so a foreground that follows another replaces the pending attempt rather
    /// than stacking a second one.
    static let shared = make()

    private static func make() -> PromoLandingDialogLaunchPresenter {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        return PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: {
                await DIContainer.remoteFeatureFlagUseCase
                    .isFeatureFlagEnabledAfterReady(for: .iosUpgradeAccountPlanRevamp)
            },
            useCase: AppOpenPromoDialogUseCase(
                promotedPlanUseCase: PromotedPlanUseCase(
                    pricingRequester: PricingRequester.shared,
                    fetchUseCase: RevampUpgradePlansUseCase(
                        productsUseCase: AccountPlanProductsUseCase(
                            purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
                            offerUseCase: StoreKitOfferUseCase(repository: StoreKitOfferRepository.newRepo)
                        ),
                        accountUseCase: accountUseCase
                    )
                ),
                accountUseCase: accountUseCase
            ),
            interruptibility: PromoDialogInterruptibility(
                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo)
            ),
            presentDialog: { fetchResult in
                AppOpenPromoLandingDialogRouter().present(fetchResult: fetchResult)
            }
        )
    }
}
