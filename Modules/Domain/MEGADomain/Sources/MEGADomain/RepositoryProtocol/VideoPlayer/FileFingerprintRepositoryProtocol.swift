import Foundation

public protocol FileFingerprintRepositoryProtocol: Sendable, RepositoryProtocol {
    /// The fingerprint the SDK computes for a file on the device, which is the same one the matching
    /// cloud node carries. `nil` when the file cannot be fingerprinted.
    func fingerprint(forFileAt url: URL) -> String?
}
