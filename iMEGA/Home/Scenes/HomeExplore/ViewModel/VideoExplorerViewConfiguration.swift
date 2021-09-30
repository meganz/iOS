

struct VideoExplorerViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return NSLocalizedString("Videos", comment: "Title for video explorer view")
    }
    
    var emptyStateType: EmptyStateType {
        return .videos
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return VideoExplorerListSource.self
    }
}

