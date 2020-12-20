
struct AudioExploreViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return NSLocalizedString("Audio", comment: "Title for audio explorer view")
    }
    
    var emptyStateViewModel: EmptyStateViewModel {
        return EmptyStateViewModel(image: UIImage(named: "audioEmptyState")!,
                                   title: NSLocalizedString("No audio files found", comment: "Audio Explorer Screen: No audio files in the account"))
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
