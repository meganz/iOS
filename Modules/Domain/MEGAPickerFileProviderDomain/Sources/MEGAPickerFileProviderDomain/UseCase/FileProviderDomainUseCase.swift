public protocol FileProviderDomainUseCaseProtocol: Sendable {
    /// Registers the MEGA domain for a logged-in account.
    func registerDomain() async throws
    /// Removes every domain the app registered, so nothing from the previous account is left in Files.
    func removeDomains() async throws
}

public struct FileProviderDomainUseCase: FileProviderDomainUseCaseProtocol {
    private let repository: any FileProviderDomainRepositoryProtocol

    public init(repository: any FileProviderDomainRepositoryProtocol) {
        self.repository = repository
    }

    public func registerDomain() async throws {
        // The legacy extension serves its location without a domain. A domain left behind by a build that
        // shipped the replicated extension would show up in Files as an empty location nothing answers for.
        guard repository.isReplicatedExtensionEnabled else {
            try await repository.removeAllDomains()
            return
        }
        try await repository.addDomain()
    }

    public func removeDomains() async throws {
        try await repository.removeAllDomains()
    }
}
