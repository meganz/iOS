import MEGADomain

/// Routes a Cloud Drive row tap. Deciding whether a file can be opened offline needs the node,
/// and looking it up is asynchronous, so a tap only leaves the synchronous path when the offline
/// guard can actually block something — every other tap opens exactly as it did before offline
/// mode existed.
@MainActor
final class OfflineAwareNodeTapDispatcher {
    private let offlineFileOpenGuard: any OfflineFileOpenGuarding
    private let nodeUseCase: any NodeUseCaseProtocol

    /// The only late-bound piece: the node browser view model owns the snack bar and is built
    /// after the search bridge, so the factory assigns this once it exists.
    var showFileUnavailableSnackBar: () -> Void = { }

    /// Rows stay tappable while the asynchronous check runs, so repeat taps on a node already
    /// being checked are dropped — otherwise the wait would let one node open (or warn) twice.
    private var handlesBeingChecked: Set<HandleEntity> = []

    init(
        offlineFileOpenGuard: some OfflineFileOpenGuarding,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.offlineFileOpenGuard = offlineFileOpenGuard
        self.nodeUseCase = nodeUseCase
    }

    /// - Parameters:
    ///   - isFolder: known synchronously at the tap site. Folders are never blocked, so passing it
    ///   here avoids resolving the node just to discover that.
    ///   - open: opens the node. It receives the entity when this dispatcher had to resolve it, so
    ///   the router can skip a second lookup; nil means the router resolves it as usual.
    func dispatch(nodeHandle: HandleEntity, isFolder: Bool, open: @escaping (NodeEntity?) -> Void) {
        guard !isFolder, offlineFileOpenGuard.isActive else {
            open(nil)
            return
        }

        guard handlesBeingChecked.insert(nodeHandle).inserted else { return }

        Task {
            defer { handlesBeingChecked.remove(nodeHandle) }

            guard let node = await nodeUseCase.nodeForHandle(nodeHandle) else {
                open(nil)
                return
            }

            if await offlineFileOpenGuard.shouldBlockOpening(node) {
                showFileUnavailableSnackBar()
                return
            }

            open(node)
        }
    }
}
