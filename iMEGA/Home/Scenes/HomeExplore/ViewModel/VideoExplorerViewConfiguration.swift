

struct VideoExplorerViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return NSLocalizedString("Videos", comment: "Title for video explorer view")
    }
    
    var emptyStateViewModel: EmptyStateViewModel {
        return EmptyStateViewModel(image: UIImage(named: "videoEmptyState")!,
                                   title: NSLocalizedString("No videos found", comment: "Video Explorer Screen: No audio files in the account"))
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return VideoExplorerListSource.self
    }
}

