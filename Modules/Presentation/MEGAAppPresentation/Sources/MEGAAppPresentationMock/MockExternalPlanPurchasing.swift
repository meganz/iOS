import Combine
import MEGAAppPresentation
import MEGADomain

@MainActor
public final class MockExternalPlanPurchasing: ExternalPlanPurchasing {
    private let subject = PassthroughSubject<PlanPurchaseOutcome, Never>()
    public private(set) var purchasedPlans: [PlanEntity] = []
    /// The handler from the most recent purchase, so a test can drive the hand-off to the browser.
    public private(set) var onWebsiteOpened: (@MainActor () -> Void)?

    public var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { subject.eraseToAnyPublisher() }

    public init() {}

    public func purchase(plan: PlanEntity, onWebsiteOpened: @escaping @MainActor () -> Void) async {
        purchasedPlans.append(plan)
        self.onWebsiteOpened = onWebsiteOpened
    }

    /// Drives the consumer through an outcome the real purchaser would emit asynchronously.
    public func send(_ outcome: PlanPurchaseOutcome) {
        subject.send(outcome)
    }
}
