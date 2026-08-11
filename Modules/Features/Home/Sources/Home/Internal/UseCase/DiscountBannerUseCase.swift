import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

protocol DiscountBannerUseCaseProtocol: Sendable {
    /// The plan whose campaign may be advertised, or `nil` when there is none or the current account
    /// has already dismissed the one on offer.
    func promotedPlan() async throws -> PlanEntity?
    /// Whether the current account has already dismissed the campaign behind `plan`.
    /// `false` when either the account or the campaign cannot be identified, so the banner stays visible.
    func isDismissed(_ plan: PlanEntity) -> Bool

    /// Records the campaign behind `plan` as dismissed for the signed in account, outliving both relaunch
    /// and logout. Only the latest dismissed campaign is kept, so a later campaign shows again.
    func dismiss(_ plan: PlanEntity)
}

package struct DiscountBannerUseCase: DiscountBannerUseCaseProtocol {
    @PreferenceWrapper(key: PreferenceKeyEntity.homeDiscountBannerDismissedCampaignIds, defaultValue: [:])
    private var dismissedCampaignIds: [String: UInt64]

    private let promotedPlanProvider: @Sendable () async throws -> PlanEntity?
    private let accountUseCase: any AccountUseCaseProtocol

    package init(
        promotedPlanProvider: @escaping @Sendable () async throws -> PlanEntity?,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.homeDiscountBanner
    ) {
        self.promotedPlanProvider = promotedPlanProvider
        self.accountUseCase = accountUseCase
        $dismissedCampaignIds.useCase = preferenceUseCase
    }

    package func promotedPlan() async throws -> PlanEntity? {
        guard let plan = try await promotedPlanProvider(), !isDismissed(plan) else { return nil }
        return plan
    }

    package func isDismissed(_ plan: PlanEntity) -> Bool {
        guard let accountKey, let campaignId = plan.campaignId else { return false }
        return dismissedCampaignIds[accountKey] == campaignId
    }

    package func dismiss(_ plan: PlanEntity) {
        guard let accountKey, let campaignId = plan.campaignId else {
            MEGALogError("[Home Promotional Banners] Could not store discount banner dismissal: missing account key or campaign id")
            return
        }
        dismissedCampaignIds[accountKey] = campaignId
    }

    private var accountKey: String? {
        accountUseCase.currentUserHandle.map(String.init)
    }
}

private extension PlanEntity {
    /// The campaign behind this plan's offer, or `nil` when the offer belongs to no campaign.
    /// The API sends `0` in that case, which must never be stored: it would suppress the banner for every
    /// later campaign-less offer on the same account.
    var campaignId: UInt64? {
        guard let campaignId = mobileOffer?.campaignId, campaignId > 0 else { return nil }
        return campaignId
    }
}

extension PreferenceUseCase where T == PreferenceRepository {
    /// Stored in its own suite so that a dismissal outlives logout, which wipes both the app and the
    static var homeDiscountBanner: PreferenceUseCase {
        PreferenceUseCase(
            repository: PreferenceRepository(
                userDefaults: UserDefaults(suiteName: "homeDiscountBanner") ?? .standard
            )
        )
    }
}
