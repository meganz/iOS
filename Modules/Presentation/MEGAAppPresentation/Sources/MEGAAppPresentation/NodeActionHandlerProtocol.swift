import MEGADomain

public enum NodesAction: Sendable {
    case download(Set<HandleEntity>)
    case toggleFavourites(Set<HandleEntity>)
    case shareLink(Set<HandleEntity>)
    case moveToRubbishBin(Set<HandleEntity>)
    case more(Set<HandleEntity>)
}

@MainActor
public protocol NodesActionHandling {
    func handle(action: NodesAction)
}
