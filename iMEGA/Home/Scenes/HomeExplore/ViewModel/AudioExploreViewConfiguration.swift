
struct AudioExploreViewConfiguration: FilesExplorerViewConfiguration {
    
    var title: String {
        return AMLocalizedString("Audio","Title for audio explorer view")
    }
    
    var emptyStateViewModel: EmptyStateViewModel {
        return EmptyStateViewModel(image: UIImage(named: "audioEmptyState")!,
                                   title: AMLocalizedString("No audio files found", "Audio Explorer Screen: No audio files in the account"))
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
