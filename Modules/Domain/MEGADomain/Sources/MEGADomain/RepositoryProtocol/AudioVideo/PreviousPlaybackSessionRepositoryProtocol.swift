import Foundation

public typealias FingerprintEntity = String

public protocol PreviousPlaybackSessionRepositoryProtocol: RepositoryProtocol, Sendable {
    func timeInterval(for fingerprint: FingerprintEntity) -> TimeInterval?
    func saveTimeInterval(_ timeInterval: TimeInterval, for fingerprint: FingerprintEntity)
    func removeSavedTimeInterval(for fingerprint: FingerprintEntity)
}
