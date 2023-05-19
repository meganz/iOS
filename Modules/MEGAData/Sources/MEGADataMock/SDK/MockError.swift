import MEGASdk

public final class MockError: MEGAError {
    var megaErrorType: MEGAErrorType
    
    public init(errorType: MEGAErrorType = .apiOk) {
        megaErrorType = errorType
    }
    
    public override var type: MEGAErrorType {
        megaErrorType
    }
    
    public static var failingError: MEGAError { MockError(errorType: .anyFailingErrorType) }
}

public extension MEGAErrorType {
    static var anyFailingErrorType: MEGAErrorType {
        let randomFailingError = Int.random(in: -29..<0)
        return MEGAErrorType(rawValue: randomFailingError) ?? .apiENoent
    }
}
