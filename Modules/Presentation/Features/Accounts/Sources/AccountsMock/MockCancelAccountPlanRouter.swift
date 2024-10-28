import Accounts
import SwiftUI

public class MockCancelAccountPlanRouter: CancelAccountPlanRouting {
    public var dismissCancellationFlow_calledTimes = 0
    public var showAppleManageSubscriptions_calledTimes = 0
    public var showSuccessAlert_calledTimes = 0
    public var showFailureAlert_calledTimes = 0
    public var lastShownSuccessAlertExpirationDate: Date?
    public var lastShownFailureAlertError: Error?

    public init() {}

    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}

    public func dismissCancellationFlow(completion: (() -> Void)?) {
        dismissCancellationFlow_calledTimes += 1
    }
    
    public func showAppleManageSubscriptions() {
        showAppleManageSubscriptions_calledTimes += 1
    }
    
    public func showAlert(_ result: CancelSubscriptionResult) {
        switch result {
        case .success(let expirationDate):
            showSuccessAlert_calledTimes += 1
            lastShownSuccessAlertExpirationDate = expirationDate
        case .failure(let error):
            showFailureAlert_calledTimes += 1
            lastShownFailureAlertError = error
        }
    }
}
