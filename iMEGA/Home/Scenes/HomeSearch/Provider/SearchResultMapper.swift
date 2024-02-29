import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import MEGASwift
import Search

/// the structure below is responsible for turning a node
/// into a fully self contained SearchResults item that has all properties needed
/// to display in the SearchResultsView
struct SearchResultMapper {
    var sdk: MEGASdk
    var nodeIconUsecase: any NodeIconUsecaseProtocol
    var nodeDetailUseCase: any NodeDetailUseCaseProtocol
    var nodeUseCase: any NodeUseCaseProtocol
    var mediaUseCase: any MediaUseCaseProtocol
    
    func map(node: NodeEntity) -> SearchResult {
        .init(
            id: node.handle,
            thumbnailDisplayMode: node.isFile ? .vertical : .horizontal,
            backgroundDisplayMode: node.hasThumbnail ? .preview : .icon,
            title: node.name,
            description: info(for: node),
            type: .node,
            properties: properties(for: node),
            thumbnailImageData: { await self.loadThumbnail(for: node) }
        )
    }
    
    private func info(for node: NodeEntity) -> @Sendable (ResultCellLayout) -> String {
        guard let megaNode = node.toMEGANode(in: sdk) else { return {_ in ""} }
        // Because of the [FM-1406] description is layout dependent, we need
        // to provide a way to customise what is shown for example for files
        // independently for list layout (we show size and creation date)
        // and for thumbnail-vertical where there's no space and we only
        // show the size. Dictionary carries all possible strings for all layouts
        // without retaining nodes or SDK
        let mapping: [ResultCellLayout: String] = {
            if node.isFile {
                return [
                    .list: Helper.sizeAndModificationDate(for: megaNode, api: sdk),
                    .thumbnail(.horizontal): "", // we do not show files in thumbnail horizontal layout
                    .thumbnail(.vertical): Helper.size(for: megaNode, api: sdk)
                ]
                
            } else {
                let value = Helper.filesAndFolders(inFolderNode: megaNode, api: sdk)
                return [
                    .list: value,
                    .thumbnail(.horizontal): value,
                    .thumbnail(.vertical): "" // we do not show folder in thumbnail vertical layout
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
    
    private func properties(for node: NodeEntity) -> [ResultProperty] {
        var properties: [ResultProperty] = []
        
        // the ordering of the properties matters for some
        // layouts where more than one property is displayed on the singe line
        // version below is modelled after previous non-customisable implementation
        // one other possible version of this code could use some kind of priority
        // so that properties could be sorted on the usage location
        if let labelImagePath = iconIndicatorPath(for: node) {
            properties.append(.label(path: labelImagePath))
        }
        
        if node.isFavourite {
            properties.append(.favorite)
        }
        
        if nodeLinked(node) {
            properties.append(.linked)
        }
        
        if node.isFile && nodeUseCase.hasVersions(nodeHandle: node.handle) {
            properties.append(.versioned)
        }
        
        if node.isTakenDown {
            properties.append(.takenDown)
        }
        
        if isDownloaded(for: node) {
            properties.append(.downloaded)
        }
        
        if isVideo(node: node), let duration = duration(for: node) {
            properties.append(contentsOf: [
                .playIcon,
                .duration(string: duration)
            ])
        }
        
        return properties
    }
    
    private func iconIndicatorPath(for node: NodeEntity) -> String? {
        guard node.label != .unknown else { return nil }
        return nodeUseCase.labelString(label: node.label)
    }
    
    private func duration(for node: NodeEntity) -> String? {
        guard isNodeVideoWithValidDuration(for: node) else { return nil }
        return TimeInterval(node.duration).timeString
    }
    
    private func isDownloaded(for node: NodeEntity) -> Bool {
        guard node.isFile else { return false }
        return nodeUseCase.isDownloaded(nodeHandle: node.handle)
    }
    
    private func isNodeVideoWithValidDuration(for node: NodeEntity) -> Bool {
        mediaUseCase.isVideo(node.name) && node.duration >= 0
    }
    
    private func isVideo(node: NodeEntity) -> Bool {
        mediaUseCase.isVideo(node.name)
    }
    
    private func nodeLinked(_ node: NodeEntity) -> Bool {
        node.isExported && !nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
    }
    
    private func loadThumbnail(for node: NodeEntity) async -> Data {
        if node.hasThumbnail {
            return await withAsyncValue(in: { completion in
                nodeDetailUseCase.loadThumbnail(
                    of: node.handle,
                    completion: { image in
                        completion(.success(image?.pngData() ?? Data()))
                    }
                )
            })
        }
        
        return nodeIconUsecase.iconData(for: node)
    }
}
