import MEGADomain
import MEGADomainMock
@testable import QuotaWarnings
import SwiftUI
import Testing

@MainActor
@Suite("QuotaDialogViewModel")
struct QuotaDialogViewModelTests {
    private func makeSUT(
        result: Result<QuotaUpgradeOption, any Error>,
        userEmail: String? = nil
    ) -> QuotaDialogViewModel {
        QuotaDialogViewModel(
            useCase: MockQuotaDialogUseCase(result: result, userEmail: userEmail),
            mapper: StubQuotaDialogMapper(),
            emailFormatter: CustomPlanEmailFormatter(appVersion: "1.2 (3)")
        )
    }

    private func entity() -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            productIdentifier: "essential.yearly",
            name: "Essential", storage: "200 GB", storageLimit: 200,
            transfer: "2 TB", transferLimit: 2048, mobileOfferLabel: nil,
            price: .yearly(.init(price: 40, currency: "EUR"))
        )
    }

    @Test func load_available_mapsToUpgradeAvailable() async {
        let sut = makeSUT(result: .success(.available(accountDetails: .build(), recommendedPlan: entity())))
        await sut.load()

        guard case let .upgradeAvailable(header, _, recommendedPlan) = sut.viewState else {
            Issue.record("Expected .upgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(header.title == StubQuotaDialogMapper.headerTitle)
        #expect(recommendedPlan.name == "mapped")
    }

    @Test func load_unavailable_mapsToNoUpgradeAvailable() async {
        let sut = makeSUT(result: .success(.unavailable(accountDetails: .build())))
        await sut.load()

        guard case .noUpgradeAvailable = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
    }

    @Test func load_throwing_mapsToError() async {
        let sut = makeSUT(result: .failure(SampleError.any))
        await sut.load()

        guard case .error = sut.viewState else {
            Issue.record("Expected .error, got \(sut.viewState)")
            return
        }
    }

    // MARK: - Tier

    /// The tier the analytics events are keyed on rides on the loaded `CurrentPlan`, so the view can build
    /// the tracking use case without the view model holding tracking state.
    @Test(arguments: [(AccountTypeEntity.free, true), (.proI, false)])
    func load_available_carriesTheLoadedTierOnTheCurrentPlan(proLevel: AccountTypeEntity, freeUser: Bool) async {
        let sut = makeSUT(
            result: .success(.available(accountDetails: .build(proLevel: proLevel), recommendedPlan: entity()))
        )

        await sut.load()

        guard case let .upgradeAvailable(_, currentPlan, _) = sut.viewState else {
            Issue.record("Expected .upgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(currentPlan.freeUser == freeUser)
    }

    @Test(arguments: [(AccountTypeEntity.free, true), (.proI, false)])
    func load_unavailable_carriesTheLoadedTierOnTheCurrentPlan(proLevel: AccountTypeEntity, freeUser: Bool) async {
        let sut = makeSUT(result: .success(.unavailable(accountDetails: .build(proLevel: proLevel))))

        await sut.load()

        guard case let .noUpgradeAvailable(_, currentPlan, _) = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(currentPlan.freeUser == freeUser)
    }

    // MARK: - Contact support

    @Test func load_unavailable_buildsTheCustomPlanSupportEmail() async {
        let sut = makeSUT(
            result: .success(.unavailable(accountDetails: .build(proLevel: .proIII))),
            userEmail: "user@mega.co.nz"
        )

        await sut.load()

        guard case let .noUpgradeAvailable(_, _, supportEmail) = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(supportEmail.recipients == ["support@mega.io"])
        #expect(supportEmail.body.contains("user@mega.co.nz (current)"))
    }
}

// MARK: - Doubles

private enum SampleError: Error { case any }

private final class MockQuotaDialogUseCase: QuotaDialogUseCaseProtocol, @unchecked Sendable {
    private let result: Result<QuotaUpgradeOption, any Error>
    let userEmail: String?

    init(result: Result<QuotaUpgradeOption, any Error>, userEmail: String? = nil) {
        self.result = result
        self.userEmail = userEmail
    }

    func upgradeOption() async throws -> QuotaUpgradeOption { try result.get() }
}

private struct StubQuotaDialogMapper: QuotaDialogMapping {
    static let headerTitle = "stub-title"

    func header(accountDetails: AccountDetailsEntity, canUpgrade: Bool) -> QuotaDialogHeader {
        QuotaDialogHeader(image: Image(systemName: "photo"), title: Self.headerTitle, subtitle: .plain(""))
    }
    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(
            name: "current",
            quota: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1, style: .usedOfTotal),
            freeUser: accountDetails.isFree
        )
    }
    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity) -> RecommendedPlan {
        RecommendedPlan(
            productIdentifier: "essential.yearly",
            name: "mapped", ribbonText: "", price: .monthly(.init(pricePerMonth: "€1")),
            storageText: "", transferText: "",
            quotaProgress: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1, style: .usedOfTotal)
        )
    }
}
