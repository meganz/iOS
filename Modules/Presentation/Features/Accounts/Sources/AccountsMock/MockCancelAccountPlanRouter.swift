import Accounts
import SwiftUI

public class MockCancelAccountPlanRouter: CancelAccountPlanRouting {
    public var dismissCancellationFlow_calledTimes = 0
    public var showAppleManageSubscriptions_calledTimes = 0
    
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}

    public func dismissCancellationFlow() {
        dismissCancellationFlow_calledTimes += 1
    }
    
    public func showAppleManageSubscriptions() {
        showAppleManageSubscriptions_calledTimes += 1
    }
}
