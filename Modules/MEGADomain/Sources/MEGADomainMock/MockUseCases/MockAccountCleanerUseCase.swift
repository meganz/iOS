import Foundation
import MEGADomain

public final class MockAccountCleanerUseCase: AccountCleanerUseCaseProcotol {
    public var isCredentialSessionsCleaned: Bool
    public var isAppGroupContainerCleaned: Bool
    
    public init(isCredentialSessionsCleaned: Bool = false, isAppGroupContainerCleaned: Bool = false) {
        self.isCredentialSessionsCleaned = isCredentialSessionsCleaned
        self.isAppGroupContainerCleaned = isAppGroupContainerCleaned
    }
    
    public func cleanCredentialSessions() {
        isCredentialSessionsCleaned = true
    }
    
    public func cleanAppGroupContainer() {
        isAppGroupContainerCleaned = true
    }
}
