import MEGADomain
@preconcurrency import MEGAPresentation

protocol NodeSensitivityChecking: Sendable {
    /// Determines whether to show the "Hide" or "Unhide" option for a given node source based on its sensitivity status.
    ///
    /// This method evaluates the sensitivity of the node source and returns:
    /// - `true`: If the node is marked as sensitive, indicating that the "Unhide" option should be shown.
    /// - `false`: If the node is not marked as sensitive, indicating that the "Hide" option should be shown.
    /// - `nil`: If no action should be taken.
    ///
    /// - Parameters:
    ///   - nodeSource: The source of the node being evaluated.
    ///   - displayMode: The current display mode.
    ///   - isFromSharedItem: A boolean indicating if the node is from a shared item.
    /// - Returns: A boolean wrapped in an optional indicating the appropriate action, or `nil` if no action is needed.
    func evaluateNodeSensitivity(
        for nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool
    ) async -> Bool?
}

struct NodeSensitivityChecker: NodeSensitivityChecking {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let systemGeneratedNodeUseCase: any SystemGeneratedNodeUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol

    init(
        featureFlagProvider: some FeatureFlagProviderProtocol,
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.systemGeneratedNodeUseCase = systemGeneratedNodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }

    func evaluateNodeSensitivity(
        for nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool
    ) async -> Bool? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              isFromSharedItem == false,
              displayMode == .cloudDrive,
              let parentNode = nodeSource.parentNode,
              parentNode.nodeType != .root,
              parentNode.isFolder else {
            return nil
        }

        do {
            // System generated nodes should not be able to be hidden or unhidden. This should be checked before account
            guard try await !systemGeneratedNodeUseCase.containsSystemGeneratedNode(nodes: [parentNode]) else {
                return nil
            }
            guard sensitiveNodeUseCase.isAccessible() else {
                return false // Always show hide regardless of the node sensitivity.
            }
            // Parent inheriting sensitivity should not be able to be hidden or unhidden.
            guard try await !sensitiveNodeUseCase.isInheritingSensitivity(node: parentNode) else {
                return nil
            }
            return parentNode.isMarkedSensitive
        } catch is CancellationError {

            MEGALogError("[\(type(of: self))] evaluateNodeSensitivity for node \(nodeLoggingInfo(for: nodeSource)) cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] Error determining node \(nodeLoggingInfo(for: nodeSource)) sensitivity. Error: \(error)")
        }
        return nil
    }

    private func nodeLoggingInfo(for nodeSource: NodeSource) -> String {
        let nodeName = nodeSource.parentNode?.name ?? "Empty Name"
        let nodeHandle = nodeSource.parentNode?.handle ?? .invalidHandle
        return "[\(nodeName) : \(nodeHandle)]"
    }
}
