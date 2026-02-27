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

@MainActor
public protocol NodesActionHandling {
    func handle(action: NodeAction)
    func handle(action: NodesAction)
}
