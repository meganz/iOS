@testable import Accounts
import Foundation
import MEGADomain

/// Records what the screen reported, so these tests neither reach real analytics nor real `UserDefaults`.
final class MockUpgradePlansAnalyticsUseCase: UpgradePlansAnalyticsUseCaseProtocol, @unchecked Sendable {
    enum Invocation: Equatable {
        case plansDidLoad
        case screenView
        case dismiss
        case getStartedForFree
        case cycleToggle(SubscriptionCycleEntity)
        case buyPlan(productIdentifier: String)
    }

    private let lock = NSLock()
    private var _invocations: [Invocation] = []

    var invocations: [Invocation] {
        lock.withLock { _invocations }
    }

    private func record(_ invocation: Invocation) {
        lock.withLock { _invocations.append(invocation) }
    }

    func plansDidLoad(_ plans: [PlanEntity], accountDetails: AccountDetailsEntity) { record(.plansDidLoad) }
    func trackScreenView() { record(.screenView) }
    func trackDismiss() { record(.dismiss) }
    func trackGetStartedForFree() { record(.getStartedForFree) }
    func trackCycleToggle(_ cycle: SubscriptionCycleEntity) { record(.cycleToggle(cycle)) }
    func trackBuyPlan(productIdentifier: String) { record(.buyPlan(productIdentifier: productIdentifier)) }
}
