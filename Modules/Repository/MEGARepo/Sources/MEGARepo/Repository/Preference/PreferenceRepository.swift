import Foundation
import MEGADomain
import MEGASwift

public final class PreferenceRepository: PreferenceRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: PreferenceRepository {
        PreferenceRepository(userDefaults: UserDefaults.standard)
    }
    
    private let userDefaults: UserDefaults
    private let lock = NSLock()
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    public func value<T>(forKey key: String) -> T? {
        lock.withLock { userDefaults.object(forKey: key) as? T }
    }
    
    public func setValue<T>(value: T?, forKey key: String) {
        lock.withLock { userDefaults.set(value, forKey: key) }
    }
}
