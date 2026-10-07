import Foundation

/// Last-page storage that the app backs with `MEGAStore`.
@MainActor
public protocol PDFViewerLastPageMEGAStoreProtocol {
    /// The raw, 1-based stored page destination, or nil if none is stored.
    func fetchLastPageDestination(forFingerprint fingerprint: String) -> Int?
    func saveLastPageDestination(_ destination: Int, forFingerprint fingerprint: String)
    func deleteLastPageDestination(forFingerprint fingerprint: String)
}
