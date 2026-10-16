import Foundation
import MEGADomain

public final class MockFileFingerprintRepository: FileFingerprintRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockFileFingerprintRepository {
        MockFileFingerprintRepository()
    }

    private let fingerprints: [URL: String]
    public private(set) var fingerprintedFiles: [URL] = []

    public init(fingerprints: [URL: String] = [:]) {
        self.fingerprints = fingerprints
    }

    public func fingerprint(forFileAt url: URL) -> String? {
        fingerprintedFiles.append(url)
        return fingerprints[url]
    }
}
