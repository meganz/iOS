
protocol FilesExplorerViewConfiguration {
    var title: String { get }
    var emptyStateViewModel: EmptyStateViewModel { get }
    var listSourceType: FilesExplorerListSourceProtocol.Type { get }
}

struct DocumentExplorerViewConfiguration: FilesExplorerViewConfiguration {
    var title: String {
        return AMLocalizedString("Documents","Title for document explorer view")
    }
    
    var emptyStateViewModel: EmptyStateViewModel {
        return EmptyStateViewModel(image: UIImage(named: "documentsEmptyState")!,
                                   title: AMLocalizedString("No documents found", "Photo Explorer Screen: No documents in the account"))
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
