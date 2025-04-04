import Foundation
import MEGADomain

public struct PreviousPlaybackSessionRepository: PreviousPlaybackSessionRepositoryProtocol {
    
    public static var newRepo: PreviousPlaybackSessionRepository {
        PreviousPlaybackSessionRepository(userDefaults: .standard)
    }
    
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    public func timeInterval(for fingerprint: FingerprintEntity) -> TimeInterval? {
        userDefaults.object(forKey: key(for: fingerprint)) as? TimeInterval
    }
    
    public func saveTimeInterval(_ timeInterval: TimeInterval, for fingerprint: FingerprintEntity) {
        userDefaults.set(timeInterval, forKey: key(for: fingerprint))
    }
    
    public func removeSavedTimeInterval(for fingerprint: FingerprintEntity) {
        userDefaults.removeObject(forKey: key(for: fingerprint))
    }
    
    private func key(for fingerprint: String) -> String {
        "playbackSession_\(fingerprint)"
    }
    
}
