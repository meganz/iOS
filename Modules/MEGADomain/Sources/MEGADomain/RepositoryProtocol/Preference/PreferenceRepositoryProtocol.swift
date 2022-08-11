public protocol PreferenceRepositoryProtocol: RepositoryProtocol {
    subscript<T>(key: String) -> T? { get set }
}


public struct EmptyPreferenceRepository: PreferenceRepositoryProtocol {
    public static var newRepo: EmptyPreferenceRepository {
        EmptyPreferenceRepository()
    }
    
    public subscript<T>(key: String) -> T? {
        get {
            nil
        }
        set {
            // Empty
        }
    }
}
