import MEGADomain

/// Tells when the node tree has caught up with the server. Folder comparisons wait for it.
public protocol FileProviderNodeTreeUseCaseProtocol: Sendable {
    /// Waits for the SDK to report that every change made elsewhere has been received, which it does once the node
    /// tree has caught up after login.
    /// - Returns: `false` when the updates ended first.
    func nodeTreeCaughtUp() async -> Bool
}

public struct FileProviderNodeTreeUseCase: FileProviderNodeTreeUseCaseProtocol {
    private let eventRepo: any EventRepositoryProtocol

    public init(eventRepo: any EventRepositoryProtocol) {
        self.eventRepo = eventRepo
    }

    public func nodeTreeCaughtUp() async -> Bool {
        for await event in eventRepo.eventUpdates where event.type == .nodesCurrent {
            return true
        }
        return false
    }
}
