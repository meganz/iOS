public protocol PreferenceRepositoryProtocol: RepositoryProtocol {
    subscript<T>(key: String) -> T? { get set }
}

public struct EmptyPreferenceRepository: PreferenceRepositoryProtocol {
    public static var newRepo: EmptyPreferenceRepository {
        EmptyPreferenceRepository()
    }
    
    // swiftlint:disable unused_setter_value
    public subscript<T>(key: String) -> T? {
        get {
            nil
        }
        set {
            // Empty
        }
    }
    // swiftlint:enable unused_setter_value
}
