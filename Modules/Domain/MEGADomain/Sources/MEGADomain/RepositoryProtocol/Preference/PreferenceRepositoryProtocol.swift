public protocol PreferenceRepositoryProtocol: RepositoryProtocol, Sendable {
    func value<T>(forKey key: String) -> T?
    func setValue<T>(value: T?, forKey key: String)
}

public struct EmptyPreferenceRepository: PreferenceRepositoryProtocol {
    public static var newRepo: EmptyPreferenceRepository {
        EmptyPreferenceRepository()
    }
    
    public func value<T>(forKey key: String) -> T? {
        nil
    }
        
    public func setValue<T>(value: T?, forKey key: String) {
        
    }
}
