import Foundation

public protocol AudioNodeAvailabilityRepositoryProtocol: RepositoryProtocol, Sendable {
    /// `true` when the node has been taken down for a Terms of Service violation.
    ///
    /// Answered by asking the API for a download URL: a taken-down node comes back
    /// as `apiEBlocked`. The node's local `isTakenDown` flag is not enough — a
    /// file-link node is not in the account tree at all, so the flag is unset there.
    ///
    /// Throws when the check itself could not be completed (offline, other API
    /// error). Callers decide how to treat an inconclusive answer.
    func isTakenDown(_ node: StreamingNode) async throws -> Bool
}
