public protocol PreferenceRepositoryProtocol {
    subscript<T>(key: String) -> T? { get set }
}


public struct EmptyPreferenceRepository: PreferenceRepositoryProtocol {
    public subscript<T>(key: String) -> T? {
        get {
            nil
        }
        set {
            // Empty
        }
    }
}
