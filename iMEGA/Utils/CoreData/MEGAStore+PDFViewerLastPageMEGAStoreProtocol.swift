import Foundation
import MEGAPDFViewer

@MainActor
extension MEGAStore: PDFViewerLastPageMEGAStoreProtocol {
    public func fetchLastPageDestination(forFingerprint fingerprint: String) -> Int? {
        fetchMediaDestination(withFingerprint: fingerprint)?.destination?.intValue
    }

    public func saveLastPageDestination(_ destination: Int, forFingerprint fingerprint: String) {
        insertOrUpdateMediaDestination(
            withFingerprint: fingerprint,
            destination: NSNumber(value: destination),
            timescale: nil
        )
    }

    public func deleteLastPageDestination(forFingerprint fingerprint: String) {
        deleteMediaDestination(withFingerprint: fingerprint)
    }
}
