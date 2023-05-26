import MEGADomain

public final class MockRatingRequestBaseConditionsUseCase: RatingRequestBaseConditionsUseCaseProtocol {
    var hasMet: Bool
    var savedVersion: String
    
    public init(hasMetBaseCondition: Bool, savedVersion: String = "") {
        hasMet = hasMetBaseCondition
        self.savedVersion = savedVersion
    }
    
    public func hasMetBaseConditions() -> Bool {
        hasMet
    }
    
    public func saveLastRequestedAppVersion(_ appVersion: String) {
        savedVersion = appVersion
    }
}
