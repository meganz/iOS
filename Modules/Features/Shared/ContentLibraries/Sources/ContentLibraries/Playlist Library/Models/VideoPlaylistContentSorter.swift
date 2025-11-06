import MEGADomain

public enum VideoPlaylistContentSorter {
    
    public static func sort(_ videos: [NodeEntity], by sortOrder: SortOrderEntity) async -> [NodeEntity] {
        switch sortOrder {
        case .defaultAsc:
            videos.sorted { $0.name < $1.name }
        case .defaultDesc:
            videos.sorted { $0.name > $1.name }
        case .modificationAsc:
            videos.sorted { $0.modificationTime < $1.modificationTime }
        case .modificationDesc:
            videos.sorted { $0.modificationTime > $1.modificationTime }
        default:
            videos
        }
    }
}
