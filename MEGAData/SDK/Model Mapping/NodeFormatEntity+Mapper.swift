import MEGADomain

extension NodeFormatEntity {
    func toMEGANodeFormatType() -> MEGANodeFormatType {
        switch self {
        case .audio: return .audio
        case .document: return .document
        case .photo: return .photo
        case .video: return .video
        default: return .unknown
        }
    }
}
