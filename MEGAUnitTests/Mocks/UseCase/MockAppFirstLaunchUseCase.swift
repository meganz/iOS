import Foundation
@testable import MEGA

final class MockAppFirstLaunchUseCase: AppFirstLaunchUseCaseProcotol {
    private(set) var isFirstLaunch = true
    
    func isAppFirstLaunch() -> Bool {
        isFirstLaunch
    }
    
    func markAppAsLaunched() {
        isFirstLaunch = false
    }
}
