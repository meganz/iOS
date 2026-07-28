import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

struct RecommendedUpgradePlanUseCaseTests {
    // Real pricing use case — it's pure and deterministic, so tests exercise the actual discount math.
    private let sut = RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())

    /// Plans default to generous limits (2 TB) so cycle/price-focused tests have headroom for any
    /// zero-usage account; headroom tests set `storageLimit` / `transferLimit` explicitly.
    private func plan(
        type: AccountTypeEntity,
        name: String,
        cycle: SubscriptionCycleEntity,
        price: Decimal,
        storageLimit: Int = 2048,
        transferLimit: Int = 2048,
        storage: String = "",
        transfer: String = "",
        mobileOfferLabel: String? = nil,
        offer: SubscriptionOfferEntity? = nil,
        productIdentifier: String = ""
    ) -> PlanEntity {
        PlanEntity(
            productIdentifier: productIdentifier,
            type: type,
            name: name,
            currency: "EUR",
            subscriptionCycle: cycle,
            storageLimit: storageLimit,
            transferLimit: transferLimit,
            storage: storage,
            transfer: transfer,
            price: price,
            introductoryOffer: offer,
            mobileOfferLabel: mobileOfferLabel
        )
    }

    /// Pay-up-front offer of `total` covering `months`, i.e. a real discount vs the full price.
    private func prepaidOffer(total: Decimal, months: Int) -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(price: total, period: .init(unit: .month, value: months), periodCount: 1, paymentMode: .payUpFront)
    }

    // MARK: - Free → cheapest yearly

    @Test func free_recommendsCheapestYearly_ignoringMonthly() {
        // No tier floor: the lowest-priced yearly plan wins even if it's below Pro I. Monthly plans are never
        // recommended to a free account.
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),   // cheapest yearly → wins
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 10),           // wrong cycle → ignored
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100),
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200)
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.name == "Essential")
        #expect(result?.price == .yearly(.init(price: 40, currency: "EUR")))
    }

    @Test func free_recommendsCheapestYearly_whenEssentialAbsent() {
        let plans = [
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200),
            plan(type: .proIII, name: "Pro III", cycle: .yearly, price: 300)
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.name == "Pro II")
    }

    @Test func free_noYearlyPlans_returnsNil() {
        let plans = [plan(type: .essential, name: "Essential", cycle: .monthly, price: 5)]
        #expect(sut.recommend(for: .build(proLevel: .free), from: plans) == nil)
    }

    @Test func emptyCatalog_returnsNil() {
        #expect(sut.recommend(for: .build(proLevel: .free), from: []) == nil)
    }

    // MARK: - Target billing cycle

    @Test func paidMonthly_staysInMonthlyCycle_evenWhenAYearlyPlanIsCheaperPerMonth() {
        // A yearly plan with a lower per-month price must still be excluded for a monthly account.
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 60),   // 5/mo — cheapest per-month, wrong cycle
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 10),
            plan(type: .proII, name: "Pro II", cycle: .monthly, price: 20)
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .monthly), from: plans)
        #expect(result?.name == "Pro I")
        #expect(result?.price == .monthly(.init(price: 10, currency: "EUR")))
    }

    @Test func paidYearly_staysInYearlyCycle_evenWhenAMonthlyPlanIsCheaperPerMonth() {
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 2),            // 2/mo — cheapest per-month, wrong cycle
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),   // 3.33/mo
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100)
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Essential")
        #expect(result?.price == .yearly(.init(price: 40, currency: "EUR")))
    }

    @Test func paidWithNoneCycle_targetsYearly() {
        // A paid account with an unresolved (.none) cycle falls back to a yearly recommendation.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 5),
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40)
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .none), from: plans)
        #expect(result?.name == "Essential")
    }

    // MARK: - Storage / transfer headroom

    @Test func recommendsCheapestPlanThatFitsStorage() {
        // Usage is 500 GB. The cheapest plan (400 GB) can't clear the dialog, so the cheapest plan with
        // enough storage headroom wins — the minimal sufficient upgrade.
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40, storageLimit: 400),  // too small → excluded
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 2048),         // fits, cheapest that fits
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 8192)
        ]
        let account = AccountDetailsEntity.build(storageUsed: 500.gigabytesToBytes(), proLevel: .proI, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro I")
    }

    @Test func planWithoutEnoughTransfer_isExcluded() {
        // Storage fits both plans, but the cheaper one lacks transfer headroom → excluded.
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40, storageLimit: 2048, transferLimit: 100),
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 2048, transferLimit: 2048)
        ]
        let account = AccountDetailsEntity.build(transferUsed: 500.gigabytesToBytes(), proLevel: .proI, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro I")
    }

    @Test func noPlanHasEnoughStorage_returnsNil() {
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 400),
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 2048)
        ]
        let account = AccountDetailsEntity.build(storageUsed: 4096.gigabytesToBytes(), proLevel: .proII, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans) == nil)
    }

    @Test func noPlanHasEnoughTransfer_returnsNil() {
        let plans = [plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, transferLimit: 2048)]
        let account = AccountDetailsEntity.build(transferUsed: 4096.gigabytesToBytes(), proLevel: .proI, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans) == nil)
    }

    @Test func planLimitEqualToUsage_isExcluded() {
        // Headroom is strictly greater: a plan whose limit exactly equals current usage leaves zero room → excluded.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 400),   // == usage → excluded
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 2048)
        ]
        let account = AccountDetailsEntity.build(storageUsed: 400.gigabytesToBytes(), proLevel: .proI, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro II")
    }

    @Test func cheapDiscountedPlanBelowUsage_isNotRecommended() {
        // A heavily discounted small plan (1/mo) doesn't fit the account's usage, so "no downsell" is enforced
        // by the headroom filter, not a price floor. The cheapest plan that actually fits wins.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 400, offer: prepaidOffer(total: 12, months: 12)),
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 2048),
            plan(type: .proIII, name: "Pro III", cycle: .yearly, price: 300, storageLimit: 8192)
        ]
        let account = AccountDetailsEntity.build(storageUsed: 500.gigabytesToBytes(), proLevel: .proII, subscriptionCycle: .yearly)
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro II")
    }

    // MARK: - Almost full (the current plan must never be re-recommended)

    @Test func almostFull_excludesCurrentPlan_recommendsLargerPlan() {
        // The dialog fires while the account is almost full: usage (390 GB) is still below the current plan's
        // allowance (400 GB). The current plan must NOT be recommended — a strictly larger plan wins.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, storageLimit: 400),   // current plan → excluded
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 2048)
        ]
        let account = AccountDetailsEntity.build(
            storageUsed: 390.gigabytesToBytes(),
            storageMax: 400.gigabytesToBytes(),
            proLevel: .proI,
            subscriptionCycle: .yearly
        )
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro II")
    }

    @Test func almostFull_noLargerPlanAvailable_returnsNil() {
        // Almost full on the largest plan in the catalog → nothing bigger to recommend → nil (no self-recommend).
        let plans = [plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, storageLimit: 2048)]
        let account = AccountDetailsEntity.build(
            storageUsed: 2000.gigabytesToBytes(),
            storageMax: 2048.gigabytesToBytes(),
            proLevel: .proII,
            subscriptionCycle: .yearly
        )
        #expect(sut.recommend(for: account, from: plans) == nil)
    }

    @Test func almostFullTransfer_excludesCurrentPlan_recommendsLargerPlan() {
        // Same rule for the transfer dimension: transfer usage below the current transfer allowance still
        // excludes the current plan.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, transferLimit: 2048),   // current → excluded
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, transferLimit: 8192)
        ]
        let account = AccountDetailsEntity.build(
            transferUsed: 2000.gigabytesToBytes(),
            transferMax: 2048.gigabytesToBytes(),
            proLevel: .proI,
            subscriptionCycle: .yearly
        )
        #expect(sut.recommend(for: account, from: plans)?.name == "Pro II")
    }

    // MARK: - Discount override (per-month price)

    @Test func discountedHigherTier_winsWhenCheapestPerMonth() {
        // Pro III discounted to 10/mo (from 25) undercuts every regular plan → wins.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 150),   // 12.5/mo
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200), // 16.67/mo
            plan(type: .proIII, name: "Pro III", cycle: .yearly, price: 300, offer: prepaidOffer(total: 120, months: 12)) // 10/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Pro III")
    }

    @Test func discount_cheapestQualifyingDiscountWins() {
        // Two discounted tiers; the cheaper per-month wins.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 150),
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, offer: prepaidOffer(total: 96, months: 12)),  // 8/mo
            plan(type: .proIII, name: "Pro III", cycle: .yearly, price: 300, offer: prepaidOffer(total: 60, months: 12)) // 5/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Pro III")
    }

    @Test func discountNotCheapestPerMonth_regularPlanWins() {
        // Pro III's discounted per-month (20/mo) is still above the cheapest regular plan → base pick stays.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 150),   // 12.5/mo — cheapest
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200), // 16.67/mo
            plan(type: .proIII, name: "Pro III", cycle: .yearly, price: 300, offer: prepaidOffer(total: 240, months: 12)) // 20/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Pro I")
    }

    @Test func freeTrialOffer_alwaysWins() {
        // A free trial resolves to per-month 0 → the best possible deal, so it always wins.
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200, offer: prepaidOffer(total: 0, months: 12)) // 0/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.name == "Pro II")
    }

    @Test func equalPerMonth_tieBreaksToSmallerStorage() {
        // Same effective per-month price → the plan with the smaller storage limit wins.
        let plans = [
            plan(type: .proI, name: "Small", cycle: .yearly, price: 120, storageLimit: 400),
            plan(type: .proII, name: "Big", cycle: .yearly, price: 120, storageLimit: 2048)
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.name == "Small")
    }

    // MARK: - Promotional offer (per-month price)

    private func signedMobileOffer() -> MobileOfferEntity {
        MobileOfferEntity(
            id: "promo", useAsTitle: false, label: nil, discountPercentage: 50,
            flags: 0, reshowTimeout: nil, expiryDate: nil, iosOfferId: "promo",
            iosSignature: .init(offerId: "promo", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
        )
    }

    private func promoPlan(
        type: AccountTypeEntity,
        name: String,
        price: Decimal,
        promo: SubscriptionOfferEntity,
        signed: Bool = true
    ) -> PlanEntity {
        PlanEntity(
            type: type, name: name, currency: "EUR", subscriptionCycle: .yearly,
            storageLimit: 2048, transferLimit: 2048, price: price,
            mobileOffer: signed ? signedMobileOffer() : nil,
            promotionalOffer: promo
        )
    }

    @Test func validPromotionalOffer_lowersPerMonth_andWins() {
        // Pro III with a signed promo at 10/mo (from 25/mo) undercuts every regular plan, same as an intro discount.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 150),   // 12.5/mo
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200), // 16.67/mo
            promoPlan(type: .proIII, name: "Pro III", price: 300, promo: prepaidOffer(total: 120, months: 12)) // 10/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Pro III")
    }

    @Test func unsignedPromotionalOffer_isIgnored_forPerMonth() {
        // Without a signature the promo is not a valid offer, so Pro III's full 25/mo applies and Pro I wins.
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 150),   // 12.5/mo — cheapest
            promoPlan(type: .proIII, name: "Pro III", price: 300, promo: prepaidOffer(total: 120, months: 12), signed: false) // 25/mo
        ]
        let result = sut.recommend(for: .build(proLevel: .proI, subscriptionCycle: .yearly), from: plans)
        #expect(result?.name == "Pro I")
    }

    // MARK: - Entity mapping

    @Test func recommendedEntity_carriesDisplayFields() {
        let plans = [
            plan(
                type: .proI, name: "Pro I", cycle: .yearly, price: 100,
                storageLimit: 2048, transferLimit: 2048, storage: "2 TB", transfer: "2 TB",
                mobileOfferLabel: "Black Friday", productIdentifier: "pro1.yearly"
            )
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.productIdentifier == "pro1.yearly")
        #expect(result?.storage == "2 TB")
        #expect(result?.storageLimit == 2048)
        #expect(result?.transfer == "2 TB")
        #expect(result?.transferLimit == 2048)
        #expect(result?.mobileOfferLabel == "Black Friday")
    }
}
