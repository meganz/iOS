
struct AudioExploreViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return Strings.Localizable.audio
    }
    
    var emptyStateType: EmptyStateType {
        return .audio
    }
    
    var listSourceType: any FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
