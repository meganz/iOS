@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import Testing

@Suite("PromotedPlanUseCase")
struct PromotedPlanUseCaseTests {

    // MARK: - Advertising flag

    @Test("An offered plan carrying the advertising flag is promoted")
    func fetchPromotedPlan_offeredAndFlagged_returnsPlan() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1))])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proI)
    }

    @Test("An offered plan without the advertising flag is not promoted")
    func fetchPromotedPlan_offeredButUnflagged_returnsNil() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 0))])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("A bitmask without bit 0 does not promote")
    func fetchPromotedPlan_unrelatedFlagBitSet_returnsNil() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 2))])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("Bit 0 set alongside other bits still promotes")
    func fetchPromotedPlan_flagBitSetAmongOthers_returnsPlan() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 3))])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proI)
    }

    @Test("A promoted plan carries the offer it was promoted for, and the campaign that offer belongs to")
    func fetchPromotedPlan_flagged_carriesTheAdvertisableOffer() async throws {
        let advertisableOffer = campaign(flags: 1, campaignId: 2026)
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: advertisableOffer)
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.offer == advertisableOffer)
        #expect(result?.offer.isAdvertisable == true)
        #expect(result?.offer.campaignId == 2026)
    }

    @Test("A plan with no mobile offer at all is not promoted")
    func fetchPromotedPlan_noMobileOffer_returnsNil() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: nil)])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    // MARK: - Expiry

    @Test("A lapsed offer is not promoted when expiry is checked")
    func fetchPromotedPlan_expiredAndChecking_returnsNil() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, expiryDate: .distantPast))
        ])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: true) == nil)
    }

    @Test("A lapsed offer is still promoted when the caller opts out of the expiry check")
    func fetchPromotedPlan_expiredButNotChecking_returnsPlan() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, expiryDate: .distantPast))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proI)
    }

    @Test("An offer still inside its window is promoted")
    func fetchPromotedPlan_notYetExpired_returnsPlan() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, expiryDate: .distantFuture))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: true)

        #expect(result?.plan.type == .proI)
    }

    @Test("An offer with no expiry date never lapses")
    func fetchPromotedPlan_missingExpiryDateAndChecking_returnsPlan() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, expiryDate: nil))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: true)

        #expect(result?.plan.type == .proI)
    }

    @Test("The expiry gate applies to the cheapest plan, not to any offered plan")
    func fetchPromotedPlan_cheapestPlanExpired_returnsNil() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 10), mobileOffer: campaign(flags: 1, expiryDate: .distantFuture)),
            plan(type: .proII, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 1, expiryDate: .distantPast))
        ])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: true) == nil)
    }

    // MARK: - Offer applicability

    @Test("A plan with no applicable offer is not promoted")
    func fetchPromotedPlan_noApplicableOffer_returnsNil() async throws {
        let sut = makeSUT(plans: [plan(type: .proI, mobileOffer: campaign(flags: 1))])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("An unsigned promotional offer is not applicable")
    func fetchPromotedPlan_unsignedPromotionalOffer_returnsNil() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, promotionalOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, signed: false))
        ])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("A signed promotional offer is applicable")
    func fetchPromotedPlan_signedPromotionalOffer_returnsPlan() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, promotionalOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1, signed: true))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proI)
    }

    @Test("No plans at all returns nil")
    func fetchPromotedPlan_noPlans_returnsNil() async throws {
        let sut = makeSUT(plans: [])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    // MARK: - Current plan

    @Test("The plan the user already owns is excluded")
    func fetchPromotedPlan_planIsCurrentPlan_returnsNil() async throws {
        let sut = makeSUT(
            plans: [plan(type: .proI, cycle: .monthly, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1))],
            accountDetails: .build(proLevel: .proI, subscriptionCycle: .monthly)
        )

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("The same level on a different cycle is not the current plan")
    func fetchPromotedPlan_sameLevelDifferentCycle_returnsPlan() async throws {
        let sut = makeSUT(
            plans: [plan(type: .proI, cycle: .yearly, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1))],
            accountDetails: .build(proLevel: .proI, subscriptionCycle: .monthly)
        )

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.subscriptionCycle == .yearly)
    }

    // MARK: - Downgrades

    @Test("A plan below the level the user is on is not promoted, however cheap its offer is")
    func fetchPromotedPlan_cheaperLowerTierPlan_returnsHigherTierPlan() async throws {
        let sut = makeSUT(
            plans: [
                plan(type: .proI, storageLimit: 400, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 1)),
                plan(type: .proII, storageLimit: 2000, introductoryOffer: offer(perMonth: 8), mobileOffer: campaign(flags: 1)),
                plan(type: .proIII, storageLimit: 8000, introductoryOffer: offer(perMonth: 12), mobileOffer: campaign(flags: 1))
            ],
            accountDetails: .build(proLevel: .proII, subscriptionCycle: .monthly)
        )

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proIII)
    }

    @Test("Only lower plans are left once the user is on the top level")
    func fetchPromotedPlan_userOnTopLevel_returnsNil() async throws {
        let sut = makeSUT(
            plans: [
                plan(type: .proI, storageLimit: 400, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 1)),
                plan(type: .proIII, storageLimit: 8000, introductoryOffer: offer(perMonth: 12), mobileOffer: campaign(flags: 1))
            ],
            accountDetails: .build(proLevel: .proIII, subscriptionCycle: .monthly)
        )

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("The other cycle of the level the user is on is not a downgrade")
    func fetchPromotedPlan_sameLevelOtherCycle_isPromoted() async throws {
        let sut = makeSUT(
            plans: [
                plan(type: .proII, cycle: .monthly, storageLimit: 2000, introductoryOffer: offer(perMonth: 8), mobileOffer: campaign(flags: 1)),
                plan(type: .proII, cycle: .yearly, storageLimit: 2000, introductoryOffer: offer(perMonth: 6), mobileOffer: campaign(flags: 1))
            ],
            accountDetails: .build(proLevel: .proII, subscriptionCycle: .monthly)
        )

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.subscriptionCycle == .yearly)
    }

    @Test("A user on a level the plan list does not carry is offered every plan")
    func fetchPromotedPlan_currentLevelMissingFromPlans_returnsCheapestPlan() async throws {
        let sut = makeSUT(
            plans: [
                plan(type: .proI, storageLimit: 400, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 1)),
                plan(type: .proII, storageLimit: 2000, introductoryOffer: offer(perMonth: 8), mobileOffer: campaign(flags: 1))
            ],
            accountDetails: .build(proLevel: .lite, subscriptionCycle: .monthly)
        )

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proI)
    }

    // MARK: - Cheapest selection

    @Test("The cheapest per-month offer wins")
    func fetchPromotedPlan_severalOfferedPlans_returnsCheapestPerMonth() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 10), mobileOffer: campaign(flags: 1)),
            plan(type: .proII, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 1)),
            plan(type: .proIII, introductoryOffer: offer(perMonth: 7), mobileOffer: campaign(flags: 1))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proII)
    }

    @Test("Cycles are compared per month, not by their raw totals")
    func fetchPromotedPlan_mixedCycles_comparesPerMonth() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, cycle: .monthly, introductoryOffer: offer(perMonth: 6), mobileOffer: campaign(flags: 1)),
            plan(type: .proII, cycle: .yearly, introductoryOffer: prepaidYearlyOffer(total: 60), mobileOffer: campaign(flags: 1))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proII)
    }

    @Test("A tie on the per-month price goes to the yearly cycle, whatever the plan order", arguments: [false, true])
    func fetchPromotedPlan_tiedPerMonthPrice_returnsYearly(yearlyListedFirst: Bool) async throws {
        let monthly = plan(type: .proI, cycle: .monthly, introductoryOffer: offer(perMonth: 5), mobileOffer: campaign(flags: 1))
        let yearly = plan(type: .proI, cycle: .yearly, introductoryOffer: prepaidYearlyOffer(total: 60), mobileOffer: campaign(flags: 1))
        let sut = makeSUT(plans: yearlyListedFirst ? [yearly, monthly] : [monthly, yearly])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.subscriptionCycle == .yearly)
    }

    @Test("The flag gate applies to the cheapest plan, not to any offered plan")
    func fetchPromotedPlan_cheapestPlanUnflagged_returnsNil() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, introductoryOffer: offer(perMonth: 10), mobileOffer: campaign(flags: 1)),
            plan(type: .proII, introductoryOffer: offer(perMonth: 4), mobileOffer: campaign(flags: 0))
        ])

        #expect(try await sut.fetchPromotedPlan(checksForExpiry: false) == nil)
    }

    @Test("Plans without an offer never win, however cheap the plan is")
    func fetchPromotedPlan_cheapUnofferedPlan_returnsOfferedPlan() async throws {
        let sut = makeSUT(plans: [
            plan(type: .proI, price: 1, mobileOffer: campaign(flags: 1)),
            plan(type: .proII, price: 500, introductoryOffer: offer(perMonth: 20), mobileOffer: campaign(flags: 1))
        ])

        let result = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(result?.plan.type == .proII)
    }

    // MARK: - Pricing request

    @Test("Pricing is reloaded before the plans are resolved, so a withdrawn campaign is not advertised")
    func fetchPromotedPlan_whenCalled_refreshesPricingOnce() async throws {
        let pricingRequester = MockPricingRequester()
        let sut = makeSUT(plans: [], pricingRequester: pricingRequester)

        _ = try await sut.fetchPromotedPlan(checksForExpiry: false)

        #expect(pricingRequester.refreshPricingCalled == 1)
    }

    @Test("A pricing failure is propagated")
    func fetchPromotedPlan_pricingFails_throws() async {
        let sut = makeSUT(pricingRequester: MockPricingRequester(result: .failure(TestError.any)))

        await #expect(throws: TestError.any) {
            try await sut.fetchPromotedPlan(checksForExpiry: false)
        }
    }

    @Test("An account details failure is propagated")
    func fetchPromotedPlan_accountDetailsFails_throws() async {
        let sut = makeSUT(accountDetailsError: TestError.any)

        await #expect(throws: TestError.any) {
            try await sut.fetchPromotedPlan(checksForExpiry: false)
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        plans: [PlanEntity] = [],
        accountDetails: AccountDetailsEntity = .build(),
        accountDetailsError: (any Error)? = nil,
        pricingRequester: MockPricingRequester = MockPricingRequester()
    ) -> PromotedPlanUseCase {
        PromotedPlanUseCase(
            pricingRequester: pricingRequester,
            fetchUseCase: MockRevampUpgradePlansUseCase(
                plansResult: plans,
                accountDetails: accountDetails,
                accountDetailsError: accountDetailsError
            )
        )
    }

    private func plan(
        type: AccountTypeEntity,
        cycle: SubscriptionCycleEntity = .monthly,
        storageLimit: Int = 0,
        price: Decimal = 100,
        introductoryOffer: SubscriptionOfferEntity? = nil,
        promotionalOffer: SubscriptionOfferEntity? = nil,
        mobileOffer: MobileOfferEntity? = nil
    ) -> PlanEntity {
        PlanEntity(
            type: type,
            subscriptionCycle: cycle,
            storageLimit: storageLimit,
            appStorePrice: PlanPriceEntity(price: price, formattedPrice: "", currency: "USD"),
            introductoryOffer: introductoryOffer,
            mobileOffer: mobileOffer,
            promotionalOffer: promotionalOffer
        )
    }

    private func offer(perMonth price: Decimal) -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: price,
            period: BillingPeriod(unit: .month, value: 1),
            periodCount: 1,
            paymentMode: .payAsYouGo
        )
    }

    private func prepaidYearlyOffer(total price: Decimal) -> SubscriptionOfferEntity {
        SubscriptionOfferEntity(
            price: price,
            period: BillingPeriod(unit: .year, value: 1),
            periodCount: 1,
            paymentMode: .payUpFront
        )
    }

    /// - Parameter campaignId: non-zero by default, as the API only flags an offer advertisable as part of a
    ///   campaign — see ``PromotedPlanEntity``.
    private func campaign(
        flags: Int,
        signed: Bool = false,
        expiryDate: Date? = nil,
        campaignId: UInt64 = 2026
    ) -> MobileOfferEntity {
        MobileOfferEntity(
            id: "campaign",
            useAsTitle: false,
            label: nil,
            discountPercentage: 0,
            flags: flags,
            reshowTimeout: nil,
            expiryDate: expiryDate,
            iosOfferId: signed ? "promo" : nil,
            iosSignature: signed
                ? MobileOfferIosSignatureEntity(offerId: "promo", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
                : nil,
            campaignId: campaignId
        )
    }
}

// MARK: - Test doubles

private enum TestError: Error {
    case any
}

private struct MockRevampUpgradePlansUseCase: RevampUpgradePlansUseCaseProtocol {
    let plansResult: [PlanEntity]
    let accountDetails: AccountDetailsEntity
    let accountDetailsError: (any Error)?

    func plans() async -> [PlanEntity] { plansResult }

    func currentAccountDetails() async throws -> AccountDetailsEntity {
        if let accountDetailsError { throw accountDetailsError }
        return accountDetails
    }
}
