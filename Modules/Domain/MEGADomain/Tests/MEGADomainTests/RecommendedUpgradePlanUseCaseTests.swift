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
        mobileOffer: MobileOfferEntity? = nil,
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
            mobileOffer: mobileOffer
        )
    }

    /// Pay-up-front offer of `total` covering `months`, i.e. a real discount vs the full price.
    private func prepaidOffer(total: Decimal, months: Int) -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(price: total, period: .init(unit: .month, value: months), periodCount: 1, paymentMode: .payUpFront)
    }

    private func campaign(label: String?, useAsTitle: Bool = true) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "campaign",
            useAsTitle: useAsTitle,
            label: label,
            discountPercentage: 20,
            flags: 0,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil
        )
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
                productIdentifier: "pro1.yearly"
            )
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.productIdentifier == "pro1.yearly")
        #expect(result?.storage == "2 TB")
        #expect(result?.storageLimit == 2048)
        #expect(result?.transfer == "2 TB")
        #expect(result?.transferLimit == 2048)
    }

    @Test func recommendedEntity_carriesMobileOfferLabel_whenPlanHasIntroOffer() {
        let plans = [
            plan(
                type: .proI, name: "Pro I", cycle: .yearly, price: 100,
                mobileOffer: campaign(label: "Black Friday"),
                offer: prepaidOffer(total: 80, months: 12)
            )
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.mobileOfferLabel == "Black Friday")
    }

    @Test func recommendedEntity_carriesMobileOfferLabel_whenPlanHasSignedPromo() {
        let plans = [
            PlanEntity(
                type: .proI, name: "Pro I", currency: "EUR", subscriptionCycle: .yearly,
                storageLimit: 2048, transferLimit: 2048, price: 100,
                mobileOffer: MobileOfferEntity(
                    id: "promo", useAsTitle: true, label: "Black Friday", discountPercentage: 50,
                    flags: 0, reshowTimeout: nil, expiryDate: nil, iosOfferId: "promo",
                    iosSignature: .init(offerId: "promo", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
                ),
                promotionalOffer: prepaidOffer(total: 80, months: 12)
            )
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.mobileOfferLabel == "Black Friday")
    }

    @Test func recommendedEntity_omitsMobileOfferLabel_whenPlanHasNoApplicableOffer() {
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100, mobileOffer: campaign(label: "Black Friday"))
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.mobileOfferLabel == nil)
    }

    /// `useAsTitle` drives the revamp title, not this label, so it must not gate the value.
    @Test func recommendedEntity_carriesMobileOfferLabel_whenLabelIsNotFlaggedAsTitle() {
        let plans = [
            plan(
                type: .proI, name: "Pro I", cycle: .yearly, price: 100,
                mobileOffer: campaign(label: "Black Friday", useAsTitle: false),
                offer: prepaidOffer(total: 80, months: 12)
            )
        ]
        let result = sut.recommend(for: .build(proLevel: .free), from: plans)
        #expect(result?.mobileOfferLabel == "Black Friday")
    }

    // MARK: - New account (a viewer with no account yet)

    @Test func newAccount_recommendsCheapestYearly_ignoringMonthly() throws {
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 1),             // wrong cycle → ignored
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),    // cheapest yearly → wins
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100)
        ]
        let result = try sut.recommendForNewAccount(from: plans)

        #expect(result.name == "Essential")
        #expect(result.price == .yearly(.init(price: 40, currency: "EUR")))
    }

    /// A discounted higher tier can undercut a cheaper plan per month, and per-month is what ranks them.
    @Test func newAccount_prefersTheCheapestEffectivePricePerMonth() throws {
        let plans = [
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),    // 3.33/mo
            plan(
                type: .proI, name: "Pro I", cycle: .yearly, price: 100,
                offer: prepaidOffer(total: 24, months: 12)                           // 2/mo → wins
            )
        ]
        #expect(try sut.recommendForNewAccount(from: plans).name == "Pro I")
    }

    /// No allowance to clear, so a plan the equivalent free account would be excluded from still qualifies.
    @Test func newAccount_hasNoStorageOrTransferFloor() throws {
        let plans = [plan(type: .essential, name: "Essential", cycle: .yearly, price: 40, storageLimit: 20, transferLimit: 20)]

        #expect(try sut.recommendForNewAccount(from: plans).name == "Essential")
    }

    @Test func newAccount_noYearlyPlan_throws() {
        let plans = [plan(type: .essential, name: "Essential", cycle: .monthly, price: 5)]

        #expect(throws: RecommendedUpgradePlanError.noPlanToRecommend) {
            try sut.recommendForNewAccount(from: plans)
        }
    }

    @Test func newAccount_emptyCatalog_throws() {
        #expect(throws: RecommendedUpgradePlanError.noPlanToRecommend) {
            try sut.recommendForNewAccount(from: [])
        }
    }

    // MARK: - Cycle target

    /// The supplied cycle replaces the account's own: a monthly subscriber asking for yearly gets a yearly plan.
    @Test func specificCycle_overridesTheAccountCycle() {
        let plans = [
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 10),
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40),   // cheapest yearly → wins
            plan(type: .proII, name: "Pro II", cycle: .yearly, price: 200)
        ]
        let account = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)

        #expect(sut.recommend(for: account, from: plans, cycleTarget: .specific(cycle: .yearly))?.name == "Essential")
    }

    /// Naming the cycle `.fromCurrentUser` would have derived anyway must not change the answer.
    @Test func specificCycle_matchingTheAccountCycle_matchesFromCurrentUser() {
        let plans = [
            plan(type: .proII, name: "Pro II", cycle: .monthly, price: 20),
            plan(type: .proIII, name: "Pro III", cycle: .monthly, price: 30),
            plan(type: .essential, name: "Essential", cycle: .yearly, price: 40)
        ]
        let account = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)

        let specific = sut.recommend(for: account, from: plans, cycleTarget: .specific(cycle: .monthly))
        let fromCurrentUser = sut.recommend(for: account, from: plans, cycleTarget: .fromCurrentUser)

        #expect(specific?.name == fromCurrentUser?.name)
        #expect(specific?.name == "Pro II")
    }

    /// The asymmetric catalog: a tier sold yearly with no monthly counterpart. Each cycle must be answered
    /// from its own plans, so the monthly list is not left without a recommendation.
    @Test func specificCycle_asymmetricCatalog_answersEachCycleFromItsOwnPlans() {
        let plans = [
            plan(type: .lite, name: "Pro Lite", cycle: .yearly, price: 30),         // no monthly counterpart
            plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100),
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 10),
            plan(type: .proII, name: "Pro II", cycle: .monthly, price: 20)
        ]
        let account = AccountDetailsEntity.build(proLevel: .free)

        #expect(sut.recommend(for: account, from: plans, cycleTarget: .specific(cycle: .yearly))?.name == "Pro Lite")
        #expect(sut.recommend(for: account, from: plans, cycleTarget: .specific(cycle: .monthly))?.name == "Pro I")
    }

    @Test func specificCycle_noPlanInThatCycle_returnsNil() {
        let plans = [plan(type: .proI, name: "Pro I", cycle: .yearly, price: 100)]

        #expect(sut.recommend(for: .build(proLevel: .free), from: plans, cycleTarget: .specific(cycle: .monthly)) == nil)
    }

    /// The headroom rule is shared with `.fromCurrentUser`, so it still excludes plans that do not
    /// clear the account's allowance in the requested cycle.
    @Test func specificCycle_stillAppliesTheStorageAndTransferHeadroomRule() {
        let plans = [
            plan(type: .lite, name: "Pro Lite", cycle: .monthly, price: 5, storageLimit: 400, transferLimit: 400),
            plan(type: .proI, name: "Pro I", cycle: .monthly, price: 10, storageLimit: 2048, transferLimit: 2048)
        ]
        let account = AccountDetailsEntity.build(storageMax: 500.gigabytesToBytes(), transferMax: 500.gigabytesToBytes())

        #expect(sut.recommend(for: account, from: plans, cycleTarget: .specific(cycle: .monthly))?.name == "Pro I")
    }
}
