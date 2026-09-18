import Foundation
import MEGADomain

/// Where the PDF content comes from.
public enum PDFViewerDocumentSource: Sendable {
    /// The file is already on disk.
    case local(URL)
    /// The file must be downloaded to the temp folder before it can be shown.
    case node(NodeEntity)
}
