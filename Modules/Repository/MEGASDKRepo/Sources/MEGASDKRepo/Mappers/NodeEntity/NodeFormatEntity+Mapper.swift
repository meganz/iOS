import MEGADomain
import MEGASdk

extension NodeFormatEntity {
    public func toMEGANodeFormatType() -> MEGANodeFormatType {
        switch self {
        case .photo: return .photo
        case .audio: return .audio
        case .video: return .video
        case .document: return .document
        case .pdf: return .pdf
        case .presentation: return .presentation
        case .archive: return .archive
        case .program: return .program
        case .misc: return .misc
        case .spreadsheet: return .spreadsheet
        case .allDocs: return .allDocs
        default: return .unknown
        }
    }
    
    func toInt32() -> Int32 {
        Int32(toMEGANodeFormatType().rawValue)
    }
}
