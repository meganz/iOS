import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

public protocol MenuDiscountBannerUseCaseProtocol: Sendable {
    func promotedPlan() async throws -> PlanEntity?
    func dismiss(_ plan: PlanEntity)
}

public struct MenuDiscountBannerUseCase: MenuDiscountBannerUseCaseProtocol {
    private enum PreferenceKey: String, PreferenceKeyProtocol {
        case menuDiscountBannerDismissedCampaignIds
    }

    @PreferenceWrapper(key: PreferenceKey.menuDiscountBannerDismissedCampaignIds, defaultValue: [:])
    private var dismissedCampaignIds: [String: UInt64]

    private let promotedPlanProvider: @Sendable () async throws -> PlanEntity?
    private let accountUseCase: any AccountUseCaseProtocol

    public init(
        promotedPlanProvider: @escaping @Sendable () async throws -> PlanEntity?,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.menuDiscountBanner
    ) {
        self.promotedPlanProvider = promotedPlanProvider
        self.accountUseCase = accountUseCase
        $dismissedCampaignIds.useCase = preferenceUseCase
    }

    public func promotedPlan() async throws -> PlanEntity? {
        guard let plan = try await promotedPlanProvider(), !isDismissed(plan) else { return nil }
        return plan
    }

    public func dismiss(_ plan: PlanEntity) {
        guard let accountKey, let campaignId = plan.campaignId else {
            MEGALogError("[Account Menu Discount Banner] Could not store dismissal: missing account key or campaign id")
            return
        }
        dismissedCampaignIds[accountKey] = campaignId
    }

    private func isDismissed(_ plan: PlanEntity) -> Bool {
        guard let accountKey, let campaignId = plan.campaignId else { return false }
        return dismissedCampaignIds[accountKey] == campaignId
    }

    private var accountKey: String? {
        accountUseCase.currentUserHandle.map(String.init)
    }
}

private extension PlanEntity {
    var campaignId: UInt64? {
        guard let campaignId = mobileOffer?.campaignId, campaignId > 0 else { return nil }
        return campaignId
    }
}

extension PreferenceUseCase where T == PreferenceRepository {
    public static var menuDiscountBanner: PreferenceUseCase {
        PreferenceUseCase(
            repository: PreferenceRepository(
                userDefaults: UserDefaults(suiteName: "menuDiscountBanner") ?? .standard
            )
        )
    }
}
