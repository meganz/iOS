import Foundation

@propertyWrapper
final class PreferenceWrapper<T> {
    private let key: PreferenceKeyEntity
    private let defaultValue: T
    var useCase: PreferenceUseCaseProtocol
    
    init(key: PreferenceKeyEntity, defaultValue: T, useCase: PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.key = key
        self.defaultValue = defaultValue
        self.useCase = useCase
    }
    
    var projectedValue: PreferenceWrapper<T> { self }
    
    func remove() {
        useCase[key] = Optional<T>.none
    }
    
    var wrappedValue: T {
        get {
            useCase[key] ?? defaultValue
        }
        set {
            useCase[key] = newValue
        }
    }
}
