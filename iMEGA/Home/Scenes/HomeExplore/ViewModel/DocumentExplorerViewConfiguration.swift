
protocol FilesExplorerViewConfiguration {
    var title: String { get }
    var emptyStateType: EmptyStateType { get }
    var listSourceType: FilesExplorerListSourceProtocol.Type { get }
}

struct DocumentExplorerViewConfiguration: FilesExplorerViewConfiguration {
    var title: String {
        return NSLocalizedString("Documents", comment: "Title for document explorer view")
    }
    
    var emptyStateType: EmptyStateType {
        return .documents
    }
    
    var listSourceType: FilesExplorerListSourceProtocol.Type {
        return DocAndAudioListSource.self
    }
}
