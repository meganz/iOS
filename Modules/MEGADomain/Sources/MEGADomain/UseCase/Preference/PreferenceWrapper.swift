import Foundation

@propertyWrapper
public final class PreferenceWrapper<T> {
    private let key: PreferenceKeyEntity
    private let defaultValue: T
    
    public var useCase: PreferenceUseCaseProtocol
    
    public init(key: PreferenceKeyEntity, defaultValue: T, useCase: PreferenceUseCaseProtocol = PreferenceUseCase.empty) {
        self.key = key
        self.defaultValue = defaultValue
        self.useCase = useCase
    }
    
    public var projectedValue: PreferenceWrapper<T> { self }
    
    public func remove() {
        useCase[key] = Optional<T>.none
    }
    
    public var wrappedValue: T {
        get {
            useCase[key] ?? defaultValue
        }
        set {
            useCase[key] = newValue
        }
    }
}
