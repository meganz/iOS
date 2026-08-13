@testable import Accounts
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import Testing

@Suite("MenuDiscountBannerUseCase")
struct MenuDiscountBannerUseCaseTests {
    @Suite("promotedPlan")
    struct PromotedPlan {
        @Test("Returns the plan provided when its campaign has not been dismissed")
        func returnsPlanWhenNotDismissed() async throws {
            let sut = makeSUT(promotedPlan: .menuBannerPlan(campaignId: 7))

            #expect(try await sut.promotedPlan()?.mobileOffer?.campaignId == 7)
        }

        @Test("Returns nil when there is no promoted plan")
        func returnsNilWhenProviderHasNoPlan() async throws {
            let sut = makeSUT(promotedPlan: nil)

            #expect(try await sut.promotedPlan() == nil)
        }

        @Test("Propagates an error raised while fetching")
        func propagatesProviderError() async {
            struct FetchError: Error {}
            let sut = makeSUT(error: FetchError())

            await #expect(throws: FetchError.self) {
                try await sut.promotedPlan()
            }
        }

        @Test("Returns nil when this account already dismissed the campaign")
        func returnsNilWhenCampaignDismissedForSameAccount() async throws {
            let sut = makeSUT(
                promotedPlan: .menuBannerPlan(campaignId: 7),
                handle: 42,
                dismissed: ["42": 7]
            )

            #expect(try await sut.promotedPlan() == nil)
        }

        @Test("Returns the plan when a different account dismissed the campaign")
        func returnsPlanWhenCampaignDismissedForAnotherAccount() async throws {
            let sut = makeSUT(
                promotedPlan: .menuBannerPlan(campaignId: 7),
                handle: 42,
                dismissed: ["99": 7]
            )

            #expect(try await sut.promotedPlan()?.mobileOffer?.campaignId == 7)
        }

        @Test("Returns the plan when the account dismissed a different campaign")
        func returnsPlanWhenAnotherCampaignDismissed() async throws {
            let sut = makeSUT(
                promotedPlan: .menuBannerPlan(campaignId: 8),
                handle: 42,
                dismissed: ["42": 7]
            )

            #expect(try await sut.promotedPlan()?.mobileOffer?.campaignId == 8)
        }
    }

    @Suite("dismiss")
    struct Dismiss {
        @Test("Records the campaign against the signed in account")
        func recordsCampaignForAccount() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(handle: 42, preferenceUseCase: preferenceUseCase)

            sut.dismiss(.menuBannerPlan(campaignId: 7))

            #expect(dismissedCampaigns(in: preferenceUseCase) == ["42": 7])
        }

        @Test("Keeps only the latest campaign for the same account")
        func replacesPreviousCampaignForSameAccount() {
            let preferenceUseCase = MockPreferenceUseCase(dict: [dismissedKey: ["42": UInt64(7)]])
            let sut = makeSUT(handle: 42, preferenceUseCase: preferenceUseCase)

            sut.dismiss(.menuBannerPlan(campaignId: 8))

            #expect(dismissedCampaigns(in: preferenceUseCase) == ["42": 8])
        }

        @Test("Leaves other accounts' dismissals untouched")
        func keepsOtherAccountsDismissals() {
            let preferenceUseCase = MockPreferenceUseCase(dict: [dismissedKey: ["99": UInt64(7)]])
            let sut = makeSUT(handle: 42, preferenceUseCase: preferenceUseCase)

            sut.dismiss(.menuBannerPlan(campaignId: 8))

            #expect(dismissedCampaigns(in: preferenceUseCase) == ["99": 7, "42": 8])
        }

        @Test("Records nothing when the offer belongs to no campaign")
        func recordsNothingForZeroCampaignId() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(handle: 42, preferenceUseCase: preferenceUseCase)

            sut.dismiss(.menuBannerPlan(campaignId: 0))

            #expect(dismissedCampaigns(in: preferenceUseCase) == nil)
        }

        @Test("Records nothing when the plan carries no mobile offer")
        func recordsNothingWithoutMobileOffer() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(handle: 42, preferenceUseCase: preferenceUseCase)

            sut.dismiss(PlanEntity())

            #expect(dismissedCampaigns(in: preferenceUseCase) == nil)
        }

        @Test("Records nothing when there is no signed in account")
        func recordsNothingWithoutAccount() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(handle: nil, preferenceUseCase: preferenceUseCase)

            sut.dismiss(.menuBannerPlan(campaignId: 7))

            #expect(dismissedCampaigns(in: preferenceUseCase) == nil)
        }

        @Test("A dismissed campaign is no longer offered")
        func dismissalHidesThePlanOnTheNextFetch() async throws {
            let plan = PlanEntity.menuBannerPlan(campaignId: 7)
            let sut = makeSUT(promotedPlan: plan, handle: 42)

            #expect(try await sut.promotedPlan() != nil)
            sut.dismiss(plan)
            #expect(try await sut.promotedPlan() == nil)
        }
    }
}

private let dismissedKey = "menuDiscountBannerDismissedCampaignIds"

private func dismissedCampaigns(in preferenceUseCase: MockPreferenceUseCase) -> [String: UInt64]? {
    preferenceUseCase.dict[dismissedKey] as? [String: UInt64]
}

private func makeSUT(
    promotedPlan: PlanEntity? = nil,
    error: (any Error)? = nil,
    handle: HandleEntity? = 42,
    dismissed: [String: UInt64]? = nil,
    preferenceUseCase: MockPreferenceUseCase? = nil
) -> MenuDiscountBannerUseCase {
    let preference = preferenceUseCase ?? MockPreferenceUseCase(
        dict: dismissed.map { [dismissedKey: $0] } ?? [:]
    )
    return MenuDiscountBannerUseCase(
        promotedPlanProvider: {
            if let error { throw error }
            return promotedPlan
        },
        accountUseCase: MockAccountUseCase(currentUser: handle.map { UserEntity(handle: $0) }),
        preferenceUseCase: preference
    )
}
