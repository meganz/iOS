import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwift

enum NodeActionAddToDestination {
    case none
    case albumsAndVideos
    case albums
    
    var priority: Int {
        switch self {
        case .none: 0
        case .albumsAndVideos: 1
        case .albums: 2
        }
    }
    
    static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.priority > rhs.priority
    }
}

struct NodeActionViewModel {
    private struct NodeSensitivity {
        let isMarkedSensitive: Bool
        let isInheritingSensitivity: Bool
    }
    
    private let systemGeneratedNodeUseCase: any SystemGeneratedNodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    
    private let maxDetermineSensitivityTasks: Int
    
    var hasValidProOrUnexpiredBusinessAccount: Bool {
        sensitiveNodeUseCase.isAccessible()
    }
    
    init(systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         maxDetermineSensitivityTasks: Int = 500,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
         nodeUseCase: some NodeUseCaseProtocol) {
        self.systemGeneratedNodeUseCase = systemGeneratedNodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.maxDetermineSensitivityTasks = maxDetermineSensitivityTasks
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.nodeUseCase = nodeUseCase
    }
    
    /// Indicates if nodes are already hidden or not. If nodes are hidden, then show unhide action; if not, then show hide action. If no action should be shown, return nil. If nodes are from shared items, return nil.
    /// - Parameter nodes: The nodes to check to show hide entry point or not
    /// - Parameter isFromSharedItem: Indicates if the nodes are from a shared item
    /// - Parameter containsABackupNode: Indicates if the nodes contain a backup node
    /// - Returns: An `Optional<Bool>`: if value is nil, don't show entry point; if value is false, show hide action; if value is true, don't show hide action
    func isHidden(_ nodes: [NodeEntity], isFromSharedItem: Bool, containsBackupNode: Bool) async -> Bool? {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              isFromSharedItem == false,
              !containsBackupNode,
              nodes.isNotEmpty else {
            return nil
        }
        guard hasValidProOrUnexpiredBusinessAccount else {
            return false
        }
        
        return await containsOnlySensitiveNodes(for: nodes)
    }
    
    func isSensitive(node: NodeEntity) async -> Bool {
        if !remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) || !hasValidProOrUnexpiredBusinessAccount {
            false
        } else if node.isMarkedSensitive {
            true
        } else {
            (try? await sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
        }
    }
    
    /// Determine if nodes can navigate to be added to album/playlist, this only provides a valid destination if all nodes are visual media.
    /// - Parameters:
    ///   - nodes: Nodes to be added
    ///   - displayMode: Source location of this request.
    ///   - isFromSharedItem: Indicates if the nodes are from a shared item
    /// - Returns: NodeActionAddToDestination which defines which action should be presented
    func addToDestination(nodes: [NodeEntity], from displayMode: DisplayMode, isFromSharedItem: Bool) -> NodeActionAddToDestination {
        
        guard
            isFromSharedItem == false,
            [.photosTimeline, .cloudDrive].contains(displayMode),
            nodes.isNotEmpty else {
            return .none
        }
        
        var finalDestination: NodeActionAddToDestination = .none
        for node in nodes {
            let fileExtensionGroup = node.fileExtensionGroup
            guard node.isFile, fileExtensionGroup.isVisualMedia else {
                // Escape, if we find a non-visual file node
                return .none
            }
            
            let nodeDestination: NodeActionAddToDestination = switch displayMode {
            case .cloudDrive where fileExtensionGroup.isVideo:
                .albumsAndVideos
            case .cloudDrive, .photosTimeline:
                .albums
            default:
                .none // We should never enter this, due to the earlier displayMode guard
            }
            
            if nodeDestination > finalDestination {
                finalDestination = nodeDestination
            }
        }
        
        return finalDestination
    }
    
    func filesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        nodeUseCase.getFilesAndFolders(nodeHandle: nodeHandle)
    }
    
    func isRestorable(node: NodeEntity, isBackupNode: Bool) -> Bool {
        nodeUseCase.isRestorable(node: node) && !isBackupNode
    }

    func isModificationTimeUndefined(for node: NodeEntity) -> Bool {
        node.modificationTime.timeIntervalSince1970 == 0
    }

    // MARK: - Private methods

    /// Determine if nodes contains only sensitive nodes
    /// - Parameter nodes: The nodes to check if they are all sensitive
    /// - Returns: An `Optional<Bool>` if value contains inherited sensitivity it will return nil, otherwise true if all nodes are marked as sensitive. If nodes are empty it will return nil.
    private func containsOnlySensitiveNodes(for nodes: [NodeEntity]) async -> Bool? {
        guard nodes.isNotEmpty else {
            return nil
        }
        return await withTaskGroup(of: NodeSensitivity.self,
                                   returning: Optional<Bool>.self) { taskGroup in
            defer { taskGroup.cancelAll() }
            
            let maxTasks = min(maxDetermineSensitivityTasks, nodes.count)
            var iterator = nodes.makeIterator()
            
            for _ in 0..<maxTasks {
                guard let node = iterator.next(),
                      taskGroup.addTaskUnlessCancelled(operation: {
                          await combinedNodeSensitivity(for: node)
                      }) else {
                    break
                }
            }
            
            var containsOnlySensitiveNodes: Bool? = true
            for await nodeSensitivity in taskGroup {
                guard !nodeSensitivity.isInheritingSensitivity else {
                    containsOnlySensitiveNodes = nil
                    break
                }
                if !nodeSensitivity.isMarkedSensitive {
                    containsOnlySensitiveNodes = false
                }
                if let node = iterator.next() {
                    guard taskGroup.addTaskUnlessCancelled(operation: {
                        await combinedNodeSensitivity(for: node)
                    }) else {
                        break
                    }
                }
            }
            return containsOnlySensitiveNodes
        }
    }
    
    private func combinedNodeSensitivity(for node: NodeEntity) async -> NodeSensitivity {
        NodeSensitivity(
            isMarkedSensitive: node.isMarkedSensitive,
            isInheritingSensitivity: (try? await sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false)
    }
}
