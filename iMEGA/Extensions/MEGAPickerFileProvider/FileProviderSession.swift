import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGARepo

/// Process-wide single-flight loginTask for the File Provider extension.
///
/// The system can fire several concurrent enumerations for the same container. Without coordination,
/// each one sees `isLoggedIn() == 0` and calls `login()` on the shared `MEGASdk`; all but one are
/// rejected with `API_EACCESS (-11)` and surface as "Content Unavailable", even though one
/// enumeration actually succeeds. This actor ensures login + fetchNodes runs exactly once: the first
/// caller performs it, the rest await the same in-flight task.
actor FileProviderSession {
    static let shared = FileProviderSession()

    private var loginTask: Task<Void, any Error>?
    private let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)

    private var nodeTreeObservation: Task<Void, Never>?
    private var isNodeTreeCurrent = false
    private var nodeTreeWaiters: [UUID: CheckedContinuation<Bool, Never>] = [:]

    /// `notAuthenticated` carrying `PickerConstant.passcodeEnabled`, which `DocumentActionViewController`
    /// turns into the "disable your passcode" prompt instead of the generic "please log in" one.
    static var passcodeEnabledError: any Error {
        NSError(
            domain: NSFileProviderErrorDomain,
            code: NSFileProviderError.notAuthenticated.rawValue,
            userInfo: [PickerConstant.passcodeEnabled: true]
        )
    }

    func ensureReady() async throws {
        // A passcode locks MEGA out of the Files app entirely, so it has to gate every entry point and not
        // only enumeration. It is checked ahead of both the in-flight loginTask and the isLoggedIn() fast
        // path: enabling the passcode must also block a process that already logged in, and joining someone
        // else's login must not slip past the gate. The value is read from the keychain on every call, so it
        // picks up a passcode enabled while this process is alive.
        guard !credentialUseCase.isPasscodeEnabled() else {
            throw Self.passcodeEnabledError
        }

        // Await an in-flight loginTask FIRST. login() flips isLoggedIn() to non-zero before
        // fetchNodes() finishes; checking isLoggedIn() before this would let a reentrant caller
        // slip past during that window and enumerate before the node tree is ready. (IOS-7447)
        if let loginTask {
            return try await loginTask.value
        }

        // Steady state: a previous loginTask already logged in and fetched nodes.
        guard MEGASdk.shared.isLoggedIn() == 0 else { return }

        observeNodeTree()
        let task = Task {
            let authUseCase = AuthUseCase(repo: AuthRepository(sdk: MEGASdk.shared), credentialRepo: CredentialRepository.newRepo)
            guard let sessionId = authUseCase.sessionId() else {
                MEGALogError("[Picker] Can't login: no session")
                throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
            }
            do {
                try await authUseCase.login(sessionId: sessionId)
                try await NodeActionUseCase(repo: NodeActionRepository.newRepo).fetchNodes()
                await cancelResumedDownloads()
            } catch {
                throw Self.readinessError(for: error)
            }
        }
        loginTask = task

        do {
            try await task.value
        } catch {
            // Clear only on failure so a later enumeration can retry. On success we keep the
            // completed task: reentrant callers awaiting it return immediately, and a caller that
            // got cancelled mid-await can never null it out while the loginTask is still in flight.
            loginTask = nil
            throw error
        }
    }

    /// Waits for the node tree to catch up with the server, which `ensureReady()` does not: fetchNodes finishes
    /// before the changes made while the process was not running have been received.
    /// - Returns: Whether it caught up within `timeout`.
    func waitUntilNodeTreeIsCurrent(timeout: Duration) async -> Bool {
        guard !isNodeTreeCurrent else { return true }

        let id = UUID()
        let timeoutTask = Task {
            try? await Task.sleep(for: timeout)
            nodeTreeWaiters.removeValue(forKey: id)?.resume(returning: false)
        }
        defer { timeoutTask.cancel() }
        return await withCheckedContinuation { nodeTreeWaiters[id] = $0 }
    }

    /// Started before login, so that the report that follows fetchNodes is not missed.
    private func observeNodeTree() {
        guard nodeTreeObservation == nil else { return }

        let nodeTreeUseCase = FileProviderNodeTreeUseCase(eventRepo: EventRepository.newRepo)
        nodeTreeObservation = Task {
            guard await nodeTreeUseCase.nodeTreeCaughtUp() else {
                MEGALogError("[Picker] Event updates ended before the node tree caught up")
                return
            }
            MEGALogDebug("[Picker] Node tree caught up")
            isNodeTreeCurrent = true
            nodeTreeWaiters.values.forEach { $0.resume(returning: true) }
            nodeTreeWaiters = [:]
        }
    }

    /// Cancels the downloads the SDK resumed from its transfer cache while logging in.
    private func cancelResumedDownloads() async {
        let resumedDownloads = MEGASdk.shared.downloadTransfers.size
        guard resumedDownloads > 0 else { return }

        MEGALogInfo("[Picker] Cancelling \(resumedDownloads) download(s) resumed from the transfer cache")
        do {
            try await TransferUseCase(
                repo: TransferRepository.newRepo,
                metadataUseCase: MetadataUseCase(
                    metadataRepository: MetadataRepository(),
                    fileSystemRepository: FileSystemRepository.sharedRepo,
                    fileExtensionRepository: FileExtensionRepository(),
                    nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
                ),
                nodeDataRepository: NodeDataRepository.newRepo
            ).cancelDownloadTransfers()
        } catch {
            // Not fatal for the session: the extension still works, it just keeps running the stale transfers.
            MEGALogError("[Picker] Can't cancel the resumed downloads: \(error)")
        }
    }
    
    /// Translates a `fastLogin` / `fetchNodes` failure into a File Provider error.
    ///
    /// This mapping lives here rather than in `FileProviderExtension.fileProviderError(for:)` because the same
    /// SDK code means different things per operation: `apiEAccess` from `fastLogin` is an unusable session,
    /// while `apiEAccess` from `renameItem` is a permission problem on one node. Only the caller that knows it
    /// was logging in can read it as `notAuthenticated`, which is the code that makes Files offer to sign in.
    /// Everything else is left alone for the generic mapper to handle.
    private static func readinessError(for error: any Error) -> any Error {
        guard let megaError = error as? MEGAError else {
            return error
        }
        switch megaError.type {
        case .apiESid, .apiEExpired, .apiEBlocked, .apiEAccess, .apiEArgs:
            MEGALogError("[Picker] Session is no longer usable: \(megaError.type.rawValue)")
            return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
        default:
            return error
        }
    }
}
