
/// Preference use case should be mainly used inside `PreferenceWrapper` to manage preferences
public protocol PreferenceUseCaseProtocol {
    subscript<T>(key: PreferenceKeyEntity) -> T? { get set }
}

public struct PreferenceUseCase<T: PreferenceRepositoryProtocol>: PreferenceUseCaseProtocol {
    private var repo: T
    
    public init(repository: T) {
        repo = repository
    }
    
    public subscript<T>(key: PreferenceKeyEntity) -> T? {
        get {
            repo[key.rawValue]
        }
        set {
            repo[key.rawValue] = newValue
        }
    }
}

public extension PreferenceUseCase where T == EmptyPreferenceRepository {
    static var empty: PreferenceUseCase {
        PreferenceUseCase(repository: EmptyPreferenceRepository())
    }
}
