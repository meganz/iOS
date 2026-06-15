import FileProvider
import MEGAAppSDKRepo
import MEGADomain
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

    func ensureReady() async throws {
        // Await an in-flight loginTask FIRST. login() flips isLoggedIn() to non-zero before
        // fetchNodes() finishes; checking isLoggedIn() before this would let a reentrant caller
        // slip past during that window and enumerate before the node tree is ready. (IOS-7447)
        if let loginTask {
            return try await loginTask.value
        }

        // Steady state: a previous loginTask already logged in and fetched nodes.
        guard MEGASdk.shared.isLoggedIn() == 0 else { return }

        let task = Task {
            let authUseCase = AuthUseCase(repo: AuthRepository(sdk: MEGASdk.shared), credentialRepo: CredentialRepository.newRepo)
            guard let sessionId = authUseCase.sessionId() else {
                MEGALogError("[Picker] Can't login: no session")
                throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
            }
            try await authUseCase.login(sessionId: sessionId)
            try await NodeActionUseCase(repo: NodeActionRepository.newRepo).fetchNodes()
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
}
