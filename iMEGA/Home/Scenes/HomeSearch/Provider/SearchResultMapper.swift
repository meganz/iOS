import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASdk
import MEGASwift
import Search
import SwiftUI

/// the structure below is responsible for turning a node
/// into a fully self contained SearchResults item that has all properties needed
/// to display in the SearchResultsView
struct SearchResultMapper: Sendable {
    private let sdk: MEGASdk
    private let nodeIconUsecase: any NodeIconUsecaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeActions: NodeActions
    private let hiddenNodesFeatureEnabled: Bool
    private let showHiddenNodeBlur: Bool
    
    init(
        sdk: MEGASdk,
        nodeIconUsecase: some NodeIconUsecaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        nodeActions: NodeActions,
        hiddenNodesFeatureEnabled: Bool,
        showHiddenNodeBlur: Bool = true) {
        self.sdk = sdk
        self.nodeIconUsecase = nodeIconUsecase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeActions = nodeActions
        self.hiddenNodesFeatureEnabled = hiddenNodesFeatureEnabled
        self.showHiddenNodeBlur = showHiddenNodeBlur
    }
    
    func map(node: NodeEntity) -> SearchResult {
        .init(
            id: node.handle,
            thumbnailDisplayMode: node.isFile ? .vertical : .horizontal,
            backgroundDisplayMode: node.hasThumbnail ? .preview : .icon,
            title: node.name,
            note: node.description,
            tags: node.tags,
            isSensitive: isSensitive(node: node),
            hasThumbnail: node.hasThumbnail,
            description: info(for: node),
            type: .node,
            properties: properties(for: node),
            thumbnailImageData: { await self.loadThumbnail(for: node) }, 
            swipeActions: { swipeActions(for: node, viewDisplayMode: $0) }
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
            properties.append(.label(path: labelImagePath, accessibilityLabel: node.label.labelString))
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
        nodeUseCase.isDownloaded(nodeHandle: node.handle)
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

    private func swipeActions(
        for node: NodeEntity,
        viewDisplayMode: ViewDisplayMode
    ) -> [SearchResultSwipeAction] {
        guard nodeUseCase.nodeAccessLevel(nodeHandle: node.handle) == .owner, viewDisplayMode != .home else {
            return []
        }

        let turquoiseBackgroundColor = TokenColors.Support.success.swiftUI

        if nodeUseCase.isInRubbishBin(nodeHandle: node.handle) {
            if nodeUseCase.isRestorable(node: node),
               !nodeUseCase.isInRubbishBin(nodeHandle: node.restoreParentHandle) {
                return [
                    SearchResultSwipeAction(
                        image: MEGAAssets.Image.restore,
                        backgroundColor: turquoiseBackgroundColor,
                        action: {
                            nodeActions.restoreFromRubbishBin([node])
                        }
                    )
                ]
            }
        } else {
            let shareLinkSwipeAction = SearchResultSwipeAction(
                image: MEGAAssets.Image.link,
                backgroundColor: TokenColors.Support.warning.swiftUI,
                action: {
                    nodeActions.shareOrManageLink([node])
                }
            )

            let downloadSwipeAction = SearchResultSwipeAction(
                image: MEGAAssets.Image.offline,
                backgroundColor: turquoiseBackgroundColor,
                action: {
                    nodeActions.nodeDownloader([node])
                }
            )

            if viewDisplayMode != .backup {
                let moveToRubbishBinSwipeAction = SearchResultSwipeAction(
                    image: MEGAAssets.Image.rubbishBin,
                    backgroundColor: TokenColors.Support.error.swiftUI,
                    action: {
                        nodeActions.moveToRubbishBin([node])
                    }
                )

                return [moveToRubbishBinSwipeAction, shareLinkSwipeAction, downloadSwipeAction]
            }

            return [shareLinkSwipeAction, downloadSwipeAction]
        }

        return []
    }
    
    private func isSensitive(node: NodeEntity) -> Bool {
        guard hiddenNodesFeatureEnabled,
              showHiddenNodeBlur,
              sensitiveNodeUseCase.isAccessible() else { return false }
        if node.isMarkedSensitive {
            return true
        }
        return (try? sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
    }
}
