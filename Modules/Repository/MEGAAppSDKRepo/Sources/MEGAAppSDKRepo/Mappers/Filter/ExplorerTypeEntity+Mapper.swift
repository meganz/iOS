import MEGADomain

extension ExplorerTypeEntity {
    public func toNodeFormatEntity() -> NodeFormatEntity {
        switch self {
        case .audio: return .audio
        // mapping from internal Explorer type to
        // external (SDK-defined) backwards compatible .allDocs Node type
        // that contains pdf/spreadsheets/presentation/documents
        case .allDocs: return .allDocs
        case .video: return .video
        case .favourites: return .unknown
        }
    }
}
