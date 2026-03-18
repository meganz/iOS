import MEGADomain
import UIKit

public enum NodesAction: Sendable {
    case download(Set<HandleEntity>)
    case toggleFavourites(Set<HandleEntity>)
    case shareLink(Set<HandleEntity>)
    case moveToRubbishBin(Set<HandleEntity>)
    case more(Set<HandleEntity>)
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
