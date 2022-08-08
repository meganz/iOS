import MEGADomain

public final class MockPreferenceUseCase: PreferenceUseCaseProtocol {
    public var dict: [PreferenceKeyEntity: Any]
    
    public init(dict: [PreferenceKeyEntity: Any] = [:]) {
        self.dict = dict
    }
    
    public subscript<T>(key: PreferenceKeyEntity) -> T? {
        get {
            dict[key] as? T
        }
        set(newValue) {
            dict[key] = newValue
        }
    }
}
