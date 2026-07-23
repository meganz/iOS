import MEGADomain
import MEGADomainMock
import Testing
@testable import QuotaWarnings

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
            recommendedUpgradePlanUseCase: MockRecommendedUpgradePlanUseCase(recommendation: recommendation)
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
            recommendedUpgradePlanUseCase: MockRecommendedUpgradePlanUseCase(recommendation: entity())
        )

        await #expect(throws: (any Error).self) {
            try await sut.upgradeOption()
        }
    }
}
