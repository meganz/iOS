@testable import Accounts
import Foundation
import MEGAStoreKitMocks
import MEGATest
import Testing

@Suite("ExternalPurchaseLinkProvider - StoreKit adapter")
struct ExternalPurchaseLinkProviderTests {

    @Test("The request is passed through to the use case unchanged")
    func externalPurchaseLink_passesTheRequestThrough() async throws {
        let useCase = MockExternalPurchaseUseCase(
            externalPurchaseLink: .success(URL(string: "https://mega.nz/propay_1")!)
        )
        let sut = ExternalPurchaseLinkProvider(useCase: useCase)

        let url = try await sut.externalPurchaseLink(
            domain: "mega.nz",
            path: "propay_1",
            sourceApp: "iOS app Ver 16.2",
            months: 12
        )

        #expect(url == URL(string: "https://mega.nz/propay_1")!)
        #expect(useCase.actions == [
            .externalPurchaseLink(domain: "mega.nz", path: "propay_1", sourceApp: "iOS app Ver 16.2", months: 12)
        ])
    }

    @Test("A use case that cannot build a link reports the failure")
    func externalPurchaseLink_whenTheUseCaseFails_throws() async {
        let sut = ExternalPurchaseLinkProvider(
            useCase: MockExternalPurchaseUseCase(externalPurchaseLink: .failure(StubError()))
        )

        await #expect(throws: StubError.self) {
            try await sut.externalPurchaseLink(domain: "mega.nz", path: "propay_1", sourceApp: nil, months: nil)
        }
    }
}

private struct StubError: Error {}
