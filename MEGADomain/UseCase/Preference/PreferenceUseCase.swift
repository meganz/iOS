import Foundation

/// Preference use case should be mainly used inside `PreferenceWrapper` to manage preferences
protocol PreferenceUseCaseProtocol {
    subscript<T>(key: PreferenceKeyEntity) -> T? { get set }
}

struct PreferenceUseCase: PreferenceUseCaseProtocol {
    private var repo: PreferenceRepositoryProtocol
    
    init(repository: PreferenceRepositoryProtocol) {
        repo = repository
    }
    
    subscript<T>(key: PreferenceKeyEntity) -> T? {
        get {
            repo[key.rawValue]
        }
        set {
            repo[key.rawValue] = newValue
        }
    }
}

extension PreferenceUseCase {
    static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults.standard))
    }
}
