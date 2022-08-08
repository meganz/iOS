import Foundation
@testable import MEGA
import MEGADomain

final class MockRatingRequestBaseConditionsUseCase: RatingRequestBaseConditionsUseCaseProtocol {
    var hasMet: Bool
    var savedVersion: String
    
    init(hasMetBaseCondition: Bool, savedVersion: String = "") {
        hasMet = hasMetBaseCondition
        self.savedVersion = savedVersion
    }
    
    func hasMetBaseConditions() -> Bool {
        hasMet
    }
    
    func saveLastRequestedAppVersion(_ appVersion: String) {
        savedVersion = appVersion
    }
}
