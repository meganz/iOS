
struct VideoExplorerViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return Strings.Localizable.videos
    }
    
    var emptyStateType: EmptyStateType {
        return .videos
    }
    
    var listSourceType: any FilesExplorerListSourceProtocol.Type {
        return VideoExplorerListSource.self
    }
}
