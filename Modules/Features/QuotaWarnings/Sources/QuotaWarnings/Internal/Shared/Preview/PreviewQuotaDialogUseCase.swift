#if DEBUG
import MEGADomain

struct PreviewQuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    var account: AccountDetailsEntity = .mock(
        proLevel: .free,
        storageUsed: 19 * 1_073_741_824,
        storageMax: 20 * 1_073_741_824,
        transferUsed: 4 * 1_073_741_824,
        transferMax: 5 * 1_073_741_824
    )
    var plan: PlanEntity? = .mockEssentialYearly
    var userEmail: String? = "preview@mega.co.nz"
    /// Drives the signed-out dialog: no account, so no current-plan card and no usage on the recommendation.
    var signedOut = false

    func upgradeOption() async throws -> QuotaUpgradeOption {
        guard let plan else { return .unavailable(accountDetails: account) }

        let recommendedPlan = RecommendedUpgradePlanEntity(plan: plan)
        return if signedOut {
            .signIn(recommendedPlan: recommendedPlan)
        } else {
            .available(accountDetails: account, recommendedPlan: recommendedPlan)
        }
    }
}

extension PlanEntity {
    static var mockEssentialYearly: PlanEntity {
        PlanEntity(
            name: "Essential",
            subscriptionCycle: .yearly,
            storageLimit: 200,
            transferLimit: 2048,
            appStorePrice: PlanPriceEntity(price: 40.01, formattedPrice: "€40.01", currency: "EUR")
        )
    }
}

extension AccountDetailsEntity {
    static func mock(
        proLevel: AccountTypeEntity,
        storageUsed: Int64 = 0,
        storageMax: Int64 = 0,
        transferUsed: Int64 = 0,
        transferMax: Int64 = 0
    ) -> AccountDetailsEntity {
        AccountDetailsEntity(
            storageUsed: storageUsed,
            versionsStorageUsed: 0,
            storageMax: storageMax,
            transferUsed: transferUsed,
            transferMax: transferMax,
            proLevel: proLevel,
            proExpiration: 0,
            subscriptionStatus: .none,
            subscriptionRenewTime: 0,
            subscriptionMethod: nil,
            subscriptionMethodId: .none,
            subscriptionCycle: .none,
            numberUsageItems: 0,
            subscriptions: [],
            plans: [],
            storageUsedForHandle: { _ in 0 }
        )
    }
}
#endif
