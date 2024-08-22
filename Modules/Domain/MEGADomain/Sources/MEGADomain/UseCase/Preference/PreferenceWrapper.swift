import Foundation
import MEGASwift

@propertyWrapper
public final class PreferenceWrapper<T>: @unchecked Sendable {
    private let key: PreferenceKeyEntity
    private let defaultValue: T
    private let lock = NSLock()
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
        lock.withLock { useCase[key] =  Optional<T>.none }
    }
    
    public var wrappedValue: T {
        get {
            lock.withLock { useCase[key] ?? defaultValue }
        }
        set {
            lock.withLock { useCase[key] = newValue }
        }
    }
}
