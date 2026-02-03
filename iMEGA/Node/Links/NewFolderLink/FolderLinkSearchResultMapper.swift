import FolderLink
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASdk
import Search

struct FolderLinkSearchResultMapper: SearchResultsMapping {
    let sdk: MEGASdk
    let nodeValidationRepository: any NodeValidationRepositoryProtocol
    let nodeDataRepository: any NodeDataRepositoryProtocol
    let thumbnailRepository: any ThumbnailRepositoryProtocol
    let nodeIconRepository: any NodeIconRepositoryProtocol
    
    func map(node: NodeEntity) -> SearchResult {
        SearchResult(
            id: node.handle,
            isFolder: node.isFolder,
            backgroundDisplayMode: node.hasThumbnail ? .preview : .icon,
            title: name(for: node),
            note: node.description,
            tags: node.tags,
            isSensitive: false,
            hasThumbnail: node.hasThumbnail,
            description: info(for: node),
            type: .node,
            properties: properties(for: node),
            thumbnailImageData: { await self.loadThumbnail(for: node) },
            swipeActions: { _ in [] }
        )
    }
    
    private func name(for node: NodeEntity) -> String {
        if node.isNodeKeyDecrypted {
            node.name
        } else if node.isFile {
            Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(1)
        } else {
            Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
        }
    }
    
    // Copied from SearchResultMapper
    private func info(for node: NodeEntity) -> @Sendable (ResultCellLayout) -> String {
        guard let megaNode = node.toMEGANode(in: sdk) else { return {_ in ""} }
        let mapping: [ResultCellLayout: String] = {
            if node.isFile {
                [
                    .list: Helper.sizeAndModificationDate(for: megaNode, api: sdk),
                    .thumbnail: Helper.size(for: megaNode, api: sdk)
                ]
                
            } else {
                [
                    .list: Helper.filesAndFolders(inFolderNode: megaNode, api: sdk),
                    .thumbnail: ""
                ]
            }
        }()
        
        return { layout in
            guard let description = mapping[layout] else {
                MEGALogError("requested invalid description for unhandled layout \(layout)")
                return ""
            }
            return description
        }
    }
    
    /// Folder link only cares about label, favourite and download properties
    /// Although we can't favourite node in folder link, we can open a folder link owned by us
    /// so that favourite property can be shown in that case.
    private func properties(for node: NodeEntity) -> [ResultProperty] {
        var properties: [ResultProperty] = []
        
        if let labelImagePath = iconIndicatorPath(for: node) {
            properties.append(.label(path: labelImagePath, accessibilityLabel: node.label.labelString))
        }
        
        if node.isFavourite {
            properties.append(.favorite)
        }
        
        if nodeValidationRepository.isDownloaded(nodeHandle: node.handle) {
            properties.append(.downloaded)
        }
        
        return properties
    }
    
    private func iconIndicatorPath(for node: NodeEntity) -> String? {
        guard node.label != .unknown else { return nil }
        return nodeDataRepository.labelString(label: node.label)
    }
    
    private func loadThumbnail(for node: NodeEntity) async -> Data {
        guard node.hasThumbnail else {
            return nodeIconRepository.iconData(for: node)
        }
        
        let thumbnailURL = if let cachedThumbnailURL = thumbnailRepository.cachedThumbnail(for: node, type: .thumbnail) {
            cachedThumbnailURL
        } else {
            try? await thumbnailRepository.loadThumbnail(for: node, type: .thumbnail)
        }
        
        guard let thumbnailURL, let data = try? Data(contentsOf: thumbnailURL) else {
            return Data()
        }
        
        return data
    }
}
