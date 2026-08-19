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

        guard case let .upgradeAvailable(header, _, recommendedPlan, _) = sut.viewState else {
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

    // MARK: - Audience

    /// The tier the analytics events are keyed on. It used to ride on `CurrentPlan`, which is impossible now
    /// that the card can be absent, so the view model carries it instead.
    @Test(arguments: [(AccountTypeEntity.free, QuotaDialogAudience.free), (.proI, .paid)])
    func load_available_carriesTheAudience(proLevel: AccountTypeEntity, expected: QuotaDialogAudience) async {
        let sut = makeSUT(
            result: .success(.available(accountDetails: .build(proLevel: proLevel), recommendedPlan: entity()))
        )

        await sut.load()

        guard case let .upgradeAvailable(_, _, _, audience) = sut.viewState else {
            Issue.record("Expected .upgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(audience == expected)
    }

    @Test(arguments: [(AccountTypeEntity.free, QuotaDialogAudience.free), (.proI, .paid)])
    func load_unavailable_carriesTheAudience(proLevel: AccountTypeEntity, expected: QuotaDialogAudience) async {
        let sut = makeSUT(result: .success(.unavailable(accountDetails: .build(proLevel: proLevel))))

        await sut.load()

        guard case let .noUpgradeAvailable(_, _, _, audience) = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(audience == expected)
    }

    // MARK: - Current plan card

    /// Whether the card is shown is the mapper's call (transfer hides it for a free account), so the view
    /// model must pass whatever it is handed straight through — including `nil`.
    @Test func load_available_carriesTheMappedCurrentPlan() async {
        let sut = makeSUT(result: .success(.available(accountDetails: .build(), recommendedPlan: entity())))

        await sut.load()

        guard case let .upgradeAvailable(_, currentPlan, _, _) = sut.viewState else {
            Issue.record("Expected .upgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(currentPlan?.name == StubQuotaDialogMapper.currentPlanName)
    }

    @Test func load_available_hidesTheCurrentPlanCardWhenTheMapperDoesNotOfferOne() async {
        let sut = QuotaDialogViewModel(
            useCase: MockQuotaDialogUseCase(result: .success(.available(accountDetails: .build(), recommendedPlan: entity()))),
            mapper: StubQuotaDialogMapper(stubbedCurrentPlan: nil)
        )

        await sut.load()

        guard case let .upgradeAvailable(_, currentPlan, _, _) = sut.viewState else {
            Issue.record("Expected .upgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(currentPlan == nil)
    }

    // MARK: - Signed in required

    @Test func load_signIn_mapsToSignInWithNoAccountToMapAgainst() async {
        let sut = makeSUT(result: .success(.signIn(recommendedPlan: entity())))

        await sut.load()

        guard case let .signIn(header, recommendedPlan) = sut.viewState else {
            Issue.record("Expected .signIn, got \(sut.viewState)")
            return
        }
        #expect(header.title == StubQuotaDialogMapper.headerTitle)
        #expect(recommendedPlan.name == "mapped")
        /// The mapper is handed no account, so there is no usage to plot on the recommended card.
        #expect(recommendedPlan.quotaProgress == nil)
    }

    // MARK: - Contact support

    @Test func load_unavailable_buildsTheCustomPlanSupportEmail() async {
        let sut = makeSUT(
            result: .success(.unavailable(accountDetails: .build(proLevel: .proIII))),
            userEmail: "user@mega.co.nz"
        )

        await sut.load()

        guard case let .noUpgradeAvailable(_, _, supportEmail, _) = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(supportEmail.recipients == ["support@mega.io"])
        #expect(supportEmail.body.contains("user@mega.co.nz (\(StubQuotaDialogMapper.stubPlanName))"))
    }

    /// The email names the plan through the mapper, not off the card — the card is allowed to be absent.
    @Test func load_unavailable_namesThePlanEvenWithoutACurrentPlanCard() async {
        let sut = QuotaDialogViewModel(
            useCase: MockQuotaDialogUseCase(result: .success(.unavailable(accountDetails: .build(proLevel: .proIII)))),
            mapper: StubQuotaDialogMapper(stubbedCurrentPlan: nil),
            emailFormatter: CustomPlanEmailFormatter(appVersion: "1.2 (3)")
        )

        await sut.load()

        guard case let .noUpgradeAvailable(_, currentPlan, supportEmail, _) = sut.viewState else {
            Issue.record("Expected .noUpgradeAvailable, got \(sut.viewState)")
            return
        }
        #expect(currentPlan == nil)
        #expect(supportEmail.body.contains("(\(StubQuotaDialogMapper.stubPlanName))"))
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
    static let currentPlanName = "current"
    static let stubPlanName = "stub-plan"

    /// What `currentPlan(accountDetails:)` answers — `nil` stands in for a mapper that hides the card.
    var stubbedCurrentPlan: CurrentPlan? = CurrentPlan(
        name: StubQuotaDialogMapper.currentPlanName,
        quota: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1)
    )

    func header(accountDetails: AccountDetailsEntity?, canUpgrade: Bool) -> QuotaDialogHeader {
        QuotaDialogHeader(image: Image(systemName: "photo"), title: Self.headerTitle, subtitle: .plain(""))
    }

    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan? {
        stubbedCurrentPlan
    }

    func planName(accountDetails: AccountDetailsEntity) -> String {
        Self.stubPlanName
    }

    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity?) -> RecommendedPlan {
        RecommendedPlan(
            productIdentifier: "essential.yearly",
            name: "mapped", ribbonText: "", price: .monthly(.init(pricePerMonth: "€1")),
            storageText: "", transferText: "",
            // Mirrors the real mappers: no account, no usage to plot.
            quotaProgress: accountDetails == nil ? nil : QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1)
        )
    }
}
