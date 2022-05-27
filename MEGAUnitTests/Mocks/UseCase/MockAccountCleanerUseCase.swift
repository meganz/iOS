import Foundation
@testable import MEGA

final class MockAccountCleanerUseCase: AccountCleanerUseCaseProcotol {
    private(set) var isCredentialSessionsCleaned = false
    private(set) var isAppGroupContainerCleaned = false
    
    func cleanCredentialSessions() {
        isCredentialSessionsCleaned = true
    }
    
    func cleanAppGroupContainer() {
        isAppGroupContainerCleaned = true
    }
}
