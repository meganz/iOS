import Foundation

/// Where the PDF content comes from.
public enum PDFViewerDocumentSource: Sendable {
    /// The file is already on disk.
    case local(URL)
}
