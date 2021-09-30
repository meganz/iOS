
struct AudioExploreViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return NSLocalizedString("Audio", comment: "Title for audio explorer view")
    }
    
    var emptyStateType: EmptyStateType {
        return .audio
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
