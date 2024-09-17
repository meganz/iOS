import MEGASdk

public final class MockError: MEGAError {
    let megaErrorType: MEGAErrorType
    private let _name: String
    private let _value: Int64
    
    public init(
        errorType: MEGAErrorType = .apiOk,
        name: String = "MockError",
        value: Int64 = 0
    ) {
        megaErrorType = errorType
        _name = name
        _value = value
    }
    
    public override var type: MEGAErrorType { megaErrorType }
    
    public override var name: String { _name }
    
    public override var value: Int64 { _value }
    
    public static var failingError: MEGAError { MockError(errorType: .anyFailingErrorType) }
}

public extension MEGAErrorType {
    static var anyFailingErrorType: MEGAErrorType {
        // MEGAErrorType: -29...-1
        let randomFailingError = Int.random(in: MEGAErrorType.apiEPaywall.rawValue...MEGAErrorType.apiEInternal.rawValue)
        return MEGAErrorType(rawValue: randomFailingError) ?? .apiENoent
    }
    
    static func anyFailingErrorType(excluding errorTypes: [MEGAErrorType]) -> MEGAErrorType {
        guard !errorTypes.isEmpty else { return anyFailingErrorType }
        
        // MEGAErrorType: -29...-1
        var allErrorTypes = [Int](MEGAErrorType.apiEPaywall.rawValue...MEGAErrorType.apiEInternal.rawValue)
        errorTypes.forEach { error in allErrorTypes.remove(object: error.rawValue) }
        
        let defaultErrorType = MEGAErrorType.apiENoent
        let randomFailingError = allErrorTypes.randomElement() ?? defaultErrorType.rawValue
        
        return MEGAErrorType(rawValue: randomFailingError) ?? defaultErrorType
    }
}
