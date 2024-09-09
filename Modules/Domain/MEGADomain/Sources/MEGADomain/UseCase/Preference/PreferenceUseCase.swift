import Foundation

/// Preference use case should be mainly used inside `PreferenceWrapper` to manage preferences
public protocol PreferenceUseCaseProtocol: Sendable {
    subscript<T>(key: PreferenceKeyEntity) -> T? { get set }
}

public struct PreferenceUseCase<T: PreferenceRepositoryProtocol>: PreferenceUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public subscript<V>(key: PreferenceKeyEntity) -> V? {
        get {
            repo.value(forKey: key.rawValue)
        }
        set {
            repo.setValue(value: newValue, forKey: key.rawValue)
        }
    }
}

public extension PreferenceUseCase where T == EmptyPreferenceRepository {
    static var empty: PreferenceUseCase {
        PreferenceUseCase(repository: EmptyPreferenceRepository())
    }
}
