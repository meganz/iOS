import Accounts
import SwiftUI

public final class MockOnboardingUpgradeAccountRouter: OnboardingUpgradeAccountRouting {
    var showTermsAndPolicies_calledTimes = 0
    
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}
    
    public func showTermsAndPolicies() {
        showTermsAndPolicies_calledTimes += 1
    }
}
