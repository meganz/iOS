import MEGADomain
import UIKit

public enum NodesAction: Sendable {
    case download(Set<HandleEntity>)
    case toggleFavourites(Set<HandleEntity>)
    case shareLink(Set<HandleEntity>)
    case copy(Set<HandleEntity>)
    case move(Set<HandleEntity>)
    case moveToRubbishBin(Set<HandleEntity>)
}

public struct NodeAction {
    public let handle: HandleEntity
    public let sender: UIButton

    public init(handle: HandleEntity, sender: UIButton) {
        self.handle = handle
        self.sender = sender
    }
}

public struct NodeSelection {
    public let handle: HandleEntity
    public let siblings: [HandleEntity]
    
    public init(handle: HandleEntity, siblings: [HandleEntity]) {
        self.handle = handle
        self.siblings = siblings
    }
}

@MainActor
public protocol NodesActionHandling {
    func handle(action: NodeAction)
    func handle(action: NodesAction)
}

@MainActor
public protocol NodeSelectionHandling {
    func handle(selection: NodeSelection)
}

@MainActor
public protocol MoreNodeActionsPresenting {
    /// Presents the action sheet that offers bulk operations (e.g. move, copy,
    /// share) on the given nodes.
    ///
    /// - Parameters:
    ///   - handles: The set of node handles for which actions should be shown.
    ///   - completion: Called when an action is selected.
    func presentActions(for handles: Set<HandleEntity>, completion: @escaping () -> Void)
}
