@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("AppOpenPromoDialogUseCase")
struct AppOpenPromoDialogUseCaseTests {

    @Test("The promoted plan is presented when its campaign has reshow allowance")
    func promotedPlanToPresent_allowanceAvailable_returnsPlan() async throws {
        let sut = makeSUT(promotedPlan: plan(campaignId: 2026), isAllowanceAvailable: true)

        #expect(try await sut.promotedPlanToPresent()?.promotedPlan.plan.type == .proI)
    }

    @Test("The dialog is told that other plans are on offer too")
    func promotedPlanToPresent_multipleOffers_carriesTheVerdict() async throws {
        let sut = makeSUT(promotedPlan: plan(campaignId: 2026), hasMultipleOffers: true)

        #expect(try await sut.promotedPlanToPresent()?.hasMultipleOffers == true)
    }

    @Test("Nothing is presented when the campaign is still inside its reshow interval")
    func promotedPlanToPresent_allowanceSpent_returnsNil() async throws {
        let sut = makeSUT(promotedPlan: plan(campaignId: 2026), isAllowanceAvailable: false)

        #expect(try await sut.promotedPlanToPresent() == nil)
    }

    @Test("Nothing is presented when no plan carries an advertisable offer")
    func promotedPlanToPresent_noPromotedPlan_returnsNil() async throws {
        let sut = makeSUT(promotedPlan: nil, isAllowanceAvailable: true)

        #expect(try await sut.promotedPlanToPresent() == nil)
    }

    @Test("A failing offer resolution is propagated rather than reported as no offer")
    func promotedPlanToPresent_fetchFails_throws() async {
        let sut = makeSUT(
            promotedPlan: nil,
            promotedPlanError: CancellationError(),
            isAllowanceAvailable: true
        )

        await #expect(throws: CancellationError.self) {
            _ = try await sut.promotedPlanToPresent()
        }
    }

    // MARK: - Gating

    @Test("The gate consulted is the one for the offer being advertised, on the account currently in")
    func promotedPlanToPresent_withOffer_gatesOnThatCampaignAndAccount() async throws {
        let allowances = MockPromoDialogReshowAllowanceFactory(isAvailable: true)
        let sut = makeSUT(
            promotedPlan: plan(campaignId: 2026),
            allowances: allowances,
            currentUserHandle: 7
        )

        _ = try await sut.promotedPlanToPresent()

        #expect(allowances.requested == [MockPromoDialogReshowAllowanceFactory.Request(
            accountHandle: 7,
            campaignId: 2026
        )])
    }

    @Test("Recording a showing spends the allowance for that campaign")
    func recordDialogShown_withOffer_consumesTheOffersAllowance() {
        let allowances = MockPromoDialogReshowAllowanceFactory(isAvailable: true)
        let sut = makeSUT(promotedPlan: nil, allowances: allowances)

        sut.recordDialogShown(for: plan(campaignId: 2026))

        #expect(allowances.consumedCampaignIds == [2026])
    }

    // MARK: - Logged out

    @Test("A session with no account has no gate to consult, so nothing is presented and nothing is recorded")
    func loggedOut_presentsNothingAndRecordsNothing() async throws {
        let allowances = MockPromoDialogReshowAllowanceFactory(isAvailable: true)
        let sut = makeSUT(
            promotedPlan: plan(campaignId: 2026),
            allowances: allowances,
            currentUserHandle: nil
        )

        #expect(try await sut.promotedPlanToPresent() == nil)

        sut.recordDialogShown(for: plan(campaignId: 2026))

        #expect(allowances.requested.isEmpty)
        #expect(allowances.consumedCampaignIds.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(
        promotedPlan: PromotedPlanEntity?,
        hasMultipleOffers: Bool = false,
        promotedPlanError: (any Error)? = nil,
        isAllowanceAvailable: Bool = true,
        allowances: MockPromoDialogReshowAllowanceFactory? = nil,
        currentUserHandle: HandleEntity? = 1
    ) -> AppOpenPromoDialogUseCase {
        let allowances = allowances ?? MockPromoDialogReshowAllowanceFactory(isAvailable: isAllowanceAvailable)
        let fetchResult = promotedPlan.map {
            PromotedPlanFetchResult(promotedPlan: $0, hasMultipleOffers: hasMultipleOffers)
        }
        return AppOpenPromoDialogUseCase(
            promotedPlanUseCase: MockPromotedPlanUseCase(fetchResult: fetchResult, error: promotedPlanError),
            accountUseCase: MockAccountUseCase(currentUser: currentUserHandle.map { UserEntity(handle: $0) }),
            makeAllowance: allowances.makeAllowance
        )
    }

    private func plan(campaignId: UInt64, reshowTimeout: TimeInterval? = 3600) -> PromotedPlanEntity {
        let offer = MobileOfferEntity(
            id: "black-friday-2026",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: reshowTimeout,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: campaignId
        )
        return PromotedPlanEntity(
            plan: PlanEntity(
                type: .proI,
                appStorePrice: PlanPriceEntity(price: 100, formattedPrice: "", currency: "USD"),
                mobileOffer: offer
            ),
            offer: offer
        )
    }
}

// MARK: - Test doubles

private struct MockPromotedPlanUseCase: PromotedPlanUseCaseProtocol {
    let fetchResult: PromotedPlanFetchResult?
    let error: (any Error)?

    func fetchPromotedPlan(checksForExpiry: Bool) async throws -> PromotedPlanFetchResult? {
        if let error { throw error }
        return fetchResult
    }
}

/// Stands in for the gate the use case builds per campaign, and records what it was asked for: the use case decides
/// which account and campaign are gated, so that is what the tests assert on.
private final class MockPromoDialogReshowAllowanceFactory: @unchecked Sendable {
    struct Request: Equatable {
        let accountHandle: HandleEntity
        let campaignId: UInt64
    }

    @Atomic var requested: [Request] = []
    @Atomic var consumedCampaignIds: [UInt64] = []

    private let isAvailable: Bool

    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
    }

    var makeAllowance: @Sendable (HandleEntity, MobileOfferEntity) -> any PromoDialogReshowAllowing {
        { [self] accountHandle, offer in
            $requested.mutate { $0.append(Request(accountHandle: accountHandle, campaignId: offer.campaignId)) }
            return MockPromoDialogReshowAllowance(isAvailable: isAvailable) { [self] in
                $consumedCampaignIds.mutate { $0.append(offer.campaignId) }
            }
        }
    }
}

private struct MockPromoDialogReshowAllowance: PromoDialogReshowAllowing {
    let isAvailable: Bool
    private let onConsume: @Sendable () -> Void

    init(isAvailable: Bool, onConsume: @escaping @Sendable () -> Void) {
        self.isAvailable = isAvailable
        self.onConsume = onConsume
    }

    func consume() { onConsume() }
}
