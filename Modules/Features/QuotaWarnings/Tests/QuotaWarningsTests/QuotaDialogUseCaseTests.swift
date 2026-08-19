import MEGADomain
import MEGADomainMock
@testable import QuotaWarnings
import Testing

@Suite("QuotaDialogUseCase")
struct QuotaDialogUseCaseTests {
    private func entity(name: String = "Essential") -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            productIdentifier: "essential.yearly",
            name: name, storage: "200 GB", storageLimit: 200,
            transfer: "2 TB", transferLimit: 2048, mobileOfferLabel: nil,
            price: .yearly(.init(price: 40, currency: "EUR"))
        )
    }

    private func makeSUT(
        account: AccountDetailsEntity = .build(proLevel: .free),
        recommendation: RecommendedUpgradePlanEntity?
    ) -> QuotaDialogUseCase {
        QuotaDialogUseCase(
            accountUseCase: MockAccountUseCase(accountDetailsResult: .success(account)),
            accountPlanProductsUseCase: MockAccountPlanProductsUseCase(),
            recommendedUpgradePlanUseCase: MockRecommendedUpgradePlanUseCase(recommendation: recommendation),
            pricingRequester: MockPricingRequester()
        )
    }

    @Test func upgradeOption_recommendationExists_isAvailableWithThatPlan() async throws {
        let expected = entity()
        let result = try await makeSUT(recommendation: expected).upgradeOption()

        guard case let .available(_, recommendedPlan) = result else {
            Issue.record("Expected .available, got \(result)")
            return
        }
        #expect(recommendedPlan == expected)
    }

    @Test func upgradeOption_noRecommendation_isUnavailable() async throws {
        let result = try await makeSUT(recommendation: nil).upgradeOption()

        guard case .unavailable = result else {
            Issue.record("Expected .unavailable, got \(result)")
            return
        }
    }

    @Test func upgradeOption_accountFetchFails_throws() async {
        let sut = QuotaDialogUseCase(
            accountUseCase: MockAccountUseCase(accountDetailsResult: .failure(.generic)),
            accountPlanProductsUseCase: MockAccountPlanProductsUseCase(),
            recommendedUpgradePlanUseCase: MockRecommendedUpgradePlanUseCase(recommendation: entity()),
            pricingRequester: MockPricingRequester()
        )

        await #expect(throws: (any Error).self) {
            try await sut.upgradeOption()
        }
    }

    // MARK: - Signed out

    @Test func upgradeOption_loggedOut_isSignInWithTheNewAccountRecommendation() async throws {
        let expected = entity()
        let result = try await makeSignedOutSUT(recommender: .init(newAccountRecommendation: .success(expected)))
            .upgradeOption()

        guard case let .signIn(recommendedPlan) = result else {
            Issue.record("Expected .signIn, got \(result)")
            return
        }
        #expect(recommendedPlan == expected)
    }

    /// The reason the signed-out dialog needs its own branch at all: `refreshCurrentAccountDetails()` fails
    /// without a session, which is what used to strand a signed-out viewer on the error state.
    @Test func upgradeOption_loggedOut_doesNotAskForAccountDetails() async throws {
        let accountUseCase = MockAccountUseCase(isLoggedIn: false, accountDetailsResult: .failure(.generic))
        let sut = QuotaDialogUseCase(
            accountUseCase: accountUseCase,
            accountPlanProductsUseCase: MockAccountPlanProductsUseCase(),
            recommendedUpgradePlanUseCase: MockRecommendedUpgradePlanUseCase(recommendation: entity()),
            pricingRequester: MockPricingRequester()
        )

        _ = try await sut.upgradeOption()

        #expect(accountUseCase.refreshAccountDetails_calledCount == 0)
    }

    /// Signed out there is no account to name in a support request, so a failed recommendation must surface as
    /// an error rather than degrade into the custom-plan state.
    @Test func upgradeOption_loggedOut_recommenderThrows_propagatesInsteadOfUnavailable() async {
        let sut = makeSignedOutSUT(
            recommender: .init(newAccountRecommendation: .failure(RecommendedUpgradePlanError.noPlanToRecommend))
        )

        await #expect(throws: RecommendedUpgradePlanError.noPlanToRecommend) {
            try await sut.upgradeOption()
        }
    }

    private func makeSignedOutSUT(recommender: MockRecommendedUpgradePlanUseCase) -> QuotaDialogUseCase {
        QuotaDialogUseCase(
            accountUseCase: MockAccountUseCase(isLoggedIn: false),
            accountPlanProductsUseCase: MockAccountPlanProductsUseCase(),
            recommendedUpgradePlanUseCase: recommender,
            pricingRequester: MockPricingRequester()
        )
    }
}
