import FileProvider

public protocol FileProviderDomainUseCaseProtocol: Sendable {
    /// Registers the MEGA domain for a logged-in account, and has the system retry the items that failed for a reason
    /// the user may have resolved in the app since. With the legacy extension, removes every domain and the replicated
    /// extension's sync data instead.
    /// - Returns: The errors whose items the system couldn't be told to retry, with why. Each is signalled on its own,
    ///   so one failing doesn't stop the others; the domain is registered all the same.
    func registerDomain() async throws -> [NSFileProviderError.Code: any Error]
    /// Removes every domain the app registered, so nothing from the previous account is left in Files.
    func removeDomains() async throws
}

public struct FileProviderDomainUseCase: FileProviderDomainUseCaseProtocol {
    /// The errors that last until the user acts in the app: signing in or turning the passcode off, renewing a business
    /// account, or getting more storage. The system stops retrying the items that fail with them until it is told.
    private static let errorCodesResolvedInApp: [NSFileProviderError.Code] = [.notAuthenticated, .cannotSynchronize, .insufficientQuota]

    private let repository: any FileProviderDomainRepositoryProtocol

    public init(repository: any FileProviderDomainRepositoryProtocol) {
        self.repository = repository
    }

    public func registerDomain() async throws -> [NSFileProviderError.Code: any Error] {
        // The legacy extension serves its location without a domain. A domain left behind by a build that
        // shipped the replicated extension would show up in Files as an empty location nothing answers for.
        // Its sync data goes with it: a domain added later starts without the items the snapshots list.
        guard repository.isReplicatedExtensionEnabled else {
            try await repository.removeAllDomains()
            try await repository.removeSyncData()
            return [:]
        }
        try await repository.addDomain()
        // The app registers the domain at every launch, once the account's nodes are loaded. An item still failing is
        // stopped again after one more try.
        var failures: [NSFileProviderError.Code: any Error] = [:]
        for code in Self.errorCodesResolvedInApp {
            do {
                try await repository.signalErrorResolved(NSFileProviderError(code))
            } catch {
                failures[code] = error
            }
        }
        return failures
    }

    public func removeDomains() async throws {
        try await repository.removeAllDomains()
    }
}
