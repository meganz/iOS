import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain

@MainActor
public final class MockPlanPurchasing: PlanPurchasing {
    private let subject = PassthroughSubject<PlanPurchaseOutcome, Never>()
    public private(set) var purchasedProductIdentifiers: [String] = []

    public var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { subject.eraseToAnyPublisher() }

    public init() {}

    public func purchase(productIdentifier: String) async {
        purchasedProductIdentifiers.append(productIdentifier)
    }

    /// Drives the consumer through an outcome the real purchaser would emit asynchronously.
    public func send(_ outcome: PlanPurchaseOutcome) {
        subject.send(outcome)
    }
}

public struct MockPlanPurchaserFactory: PlanPurchaserFactory {
    private let purchaser: MockPlanPurchasing
    private let externalPurchaser: MockExternalPlanPurchasing

    @MainActor
    public init(
        purchaser: MockPlanPurchasing,
        externalPurchaser: MockExternalPlanPurchasing = MockExternalPlanPurchasing()
    ) {
        self.purchaser = purchaser
        self.externalPurchaser = externalPurchaser
    }

    @MainActor
    public func makePurchaser(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) -> any PlanPurchasing {
        purchaser
    }

    @MainActor
    public func makeExternalPurchaser(
        linkProvider: some ExternalPurchaseLinkProviding,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        domainName: String,
        appVersion: String,
        canOpenURL: @escaping @Sendable (URL) async -> Bool,
        openURL: @escaping @Sendable (URL) async -> Void
    ) -> any ExternalPlanPurchasing {
        externalPurchaser
    }
}
