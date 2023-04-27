import MEGASdk

public final class MockError: MEGAError {
    var megaErrorType: MEGAErrorType
    
    public init(errorType: MEGAErrorType = .apiOk) {
        megaErrorType = errorType
    }
    
    public override var type: MEGAErrorType {
        megaErrorType
    }
}
