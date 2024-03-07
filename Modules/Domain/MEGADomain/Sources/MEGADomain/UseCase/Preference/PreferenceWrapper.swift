import Foundation

@propertyWrapper
public final class PreferenceWrapper<T> {
    private let key: PreferenceKeyEntity
    private let defaultValue: T
    
    public var useCase: any PreferenceUseCaseProtocol
    
    public var existed: Bool {
        let value: T? = useCase[key]
        return value != nil
    }
    
    public init(key: PreferenceKeyEntity, defaultValue: T, useCase: any PreferenceUseCaseProtocol = PreferenceUseCase.empty) {
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
