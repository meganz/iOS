import MEGADomain

extension ExplorerTypeEntity {
    func toNodeFormatEntity() -> NodeFormatEntity {
        switch self {
        case .audio: return .audio
        case .document: return .document
        case .video: return .video
        case .favourites: return .unknown
        }
    }
}
