import MEGADomain
import MEGADomainMock
import MEGAUIComponent
import SwiftUI
import Testing
@testable import QuotaWarnings

@MainActor
@Suite("QuotaDialogViewModel")
struct QuotaDialogViewModelTests {
    private func makeSUT(result: Result<QuotaUpgradeOption, any Error>) -> QuotaDialogViewModel {
        QuotaDialogViewModel(
            useCase: MockQuotaDialogUseCase(result: result),
            mapper: StubQuotaDialogMapper()
        )
    }

    private func entity() -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
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
        guard case let .storage(storageHeader) = header else {
            Issue.record("Expected a storage header")
            return
        }
        #expect(storageHeader.title == StubQuotaDialogMapper.headerTitle)
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
}

// MARK: - Doubles

private enum SampleError: Error { case any }

private final class MockQuotaDialogUseCase: QuotaDialogUseCaseProtocol, @unchecked Sendable {
    private let result: Result<QuotaUpgradeOption, any Error>
    init(result: Result<QuotaUpgradeOption, any Error>) { self.result = result }
    func upgradeOption() async throws -> QuotaUpgradeOption { try result.get() }
}

private struct StubQuotaDialogMapper: QuotaDialogMapping {
    static let headerTitle = "stub-title"

    func header(accountDetails: AccountDetailsEntity) -> QuotaDialogHeader {
        .storage(StorageQuotaHeader(image: Image(systemName: "photo"), title: Self.headerTitle, subtitle: ""))
    }
    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(name: "current", quota: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1, style: .usedOfTotal))
    }
    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity) -> RecommendedPlan {
        RecommendedPlan(
            name: "mapped", ribbonText: "", price: .monthly(.init(pricePerMonth: "€1")),
            storageText: "", transferText: "",
            quotaProgress: QuotaProgress(status: .good, usedBytes: 0, totalBytes: 1, style: .usedOfTotal)
        )
    }
}
