import Foundation

/// Preference use case should be mainly used inside `PreferenceWrapper` to manage preferences
protocol PreferenceUseCaseProtocol {
    subscript<T>(key: PreferenceKeyEntity) -> T? { get set }
}

struct PreferenceUseCase<T: PreferenceRepositoryProtocol>: PreferenceUseCaseProtocol {
    private var repo: T
    
    init(repository: T) {
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

extension PreferenceUseCase where T == PreferenceRepository {
    static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults.standard))
    }
    
    static var group: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: MEGAGroupIdentifier) ?? UserDefaults.standard))
    }
}
