import Foundation
import MEGAAppPresentation
import MEGAStoreKit

/// Satisfies ``ExternalPurchaseLinkProviding`` with the real StoreKit-backed use case, so the purchaser in
/// MEGAAppPresentation stays free of MEGAStoreKit.
struct ExternalPurchaseLinkProvider: ExternalPurchaseLinkProviding {
    private let useCase: any ExternalPurchaseUseCaseProtocol

    init(useCase: some ExternalPurchaseUseCaseProtocol) {
        self.useCase = useCase
    }

    func shouldProvideExternalPurchase() async -> Bool {
        await useCase.shouldProvideExternalPurchase()
    }

    func externalPurchaseLink(domain: String, path: String, sourceApp: String?, months: Int?) async throws -> URL {
        try await useCase.externalPurchaseLink(domain: domain, path: path, sourceApp: sourceApp, months: months)
    }
}
