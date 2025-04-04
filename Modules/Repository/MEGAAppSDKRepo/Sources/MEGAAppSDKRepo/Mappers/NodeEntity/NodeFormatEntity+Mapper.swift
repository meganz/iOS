import MEGADomain
import MEGASdk

extension NodeFormatEntity {
    public func toMEGANodeFormatType() -> MEGANodeFormatType {
        switch self {
        case .photo: .photo
        case .audio: .audio
        case .video: .video
        case .document: .document
        case .pdf: .pdf
        case .presentation: .presentation
        case .archive: .archive
        case .program: .program
        case .misc: .misc
        case .spreadsheet: .spreadsheet
        case .allDocs: .allDocs
        case .others: .others
        default: .unknown
        }
    }
}
