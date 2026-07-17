import Foundation
import MEGADomain

public final class MockSubscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCaseProtocol {
    private let planPrice: SubscriptionPlanPrice

    public init(planPrice: SubscriptionPlanPrice = .monthly(.init(price: 0, currency: ""))) {
        self.planPrice = planPrice
    }

    public func planPrice(for plan: PlanEntity) -> SubscriptionPlanPrice {
        planPrice
    }
}
