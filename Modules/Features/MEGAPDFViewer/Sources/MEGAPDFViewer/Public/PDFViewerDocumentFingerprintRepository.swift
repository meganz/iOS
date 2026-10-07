import Foundation
import MEGASdk
// Gives `@unchecked Sendable` to `MEGASdk` -> Methods on
// `PDFViewerDocumentFingerprintRepository` can be called from other isolation
// contexts
import MEGASDKRepo

public protocol PDFViewerDocumentFingerprintRepositoryProtocol: Sendable {
    /// Identifies the file, so the same document resumes wherever it was
    /// opened from. Nil when the file cannot be fingerprinted.
    func fingerprint(forFileAt url: URL) async -> String?
}

public struct PDFViewerDocumentFingerprintRepository: PDFViewerDocumentFingerprintRepositoryProtocol {
    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func fingerprint(forFileAt url: URL) async -> String? {
        sdk.fingerprint(forFilePath: url.path)
    }
}
