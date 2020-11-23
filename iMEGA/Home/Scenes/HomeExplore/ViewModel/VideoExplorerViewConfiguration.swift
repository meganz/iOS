

struct VideoExplorerViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return AMLocalizedString("Videos","Title for video explorer view")
    }
    
    var emptyStateViewModel: EmptyStateViewModel {
        return EmptyStateViewModel(image: UIImage(named: "videoEmptyState")!,
                                   title: AMLocalizedString("No videos found", "Video Explorer Screen: No audio files in the account"))
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return VideoExplorerListSource.self
    }
}

