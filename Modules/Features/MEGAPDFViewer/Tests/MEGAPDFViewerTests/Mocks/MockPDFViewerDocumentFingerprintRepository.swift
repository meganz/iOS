import Foundation
@testable import MEGAPDFViewer

struct MockPDFViewerDocumentFingerprintRepository: PDFViewerDocumentFingerprintRepositoryProtocol {
    let fingerprintResult: String?

    init(fingerprintResult: String? = "any-fingerprint") {
        self.fingerprintResult = fingerprintResult
    }

    func fingerprint(forFileAt url: URL) async -> String? {
        fingerprintResult
    }
}
