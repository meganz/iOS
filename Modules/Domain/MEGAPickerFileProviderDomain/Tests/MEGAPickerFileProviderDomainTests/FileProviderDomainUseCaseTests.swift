import FileProvider
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderDomainUseCaseTests {
    @Test
    func registerDomain_whenReplicatedExtensionIsEnabled_addsDomainAndSignalsTheErrorsResolvedInTheApp() async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: true)
        let sut = FileProviderDomainUseCase(repository: repository)

        let failures = try await sut.registerDomain()

        #expect(repository.messages == [
            .addDomain,
            .signalErrorResolved(.notAuthenticated),
            .signalErrorResolved(.cannotSynchronize),
            .signalErrorResolved(.insufficientQuota)
        ])
        #expect(failures.isEmpty)
    }

    @Test
    func registerDomain_whenSignallingOneErrorFails_signalsTheOthersAndReturnsTheFailure() async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: true, failingErrorCode: .cannotSynchronize)
        let sut = FileProviderDomainUseCase(repository: repository)

        let failures = try await sut.registerDomain()

        #expect(repository.messages == [
            .addDomain,
            .signalErrorResolved(.notAuthenticated),
            .signalErrorResolved(.cannotSynchronize),
            .signalErrorResolved(.insufficientQuota)
        ])
        #expect(Array(failures.keys) == [.cannotSynchronize])
        #expect(failures[.cannotSynchronize] as? MockError == .failed)
    }

    @Test
    func registerDomain_whenReplicatedExtensionIsDisabled_removesAllDomainsAndTheSyncData() async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: false)
        let sut = FileProviderDomainUseCase(repository: repository)

        let failures = try await sut.registerDomain()

        #expect(repository.messages == [.removeAllDomains, .removeSyncData])
        #expect(failures.isEmpty)
    }

    @Test
    func registerDomain_whenAddingFails_throws() async {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: true, error: MockError.failed)
        let sut = FileProviderDomainUseCase(repository: repository)

        await #expect(throws: MockError.failed) {
            try await sut.registerDomain()
        }
    }

    @Test(arguments: [true, false])
    func removeDomains_removesAllDomains(isReplicatedExtensionEnabled: Bool) async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: isReplicatedExtensionEnabled)
        let sut = FileProviderDomainUseCase(repository: repository)

        try await sut.removeDomains()

        #expect(repository.messages == [.removeAllDomains])
    }
}

private enum MockError: Error {
    case failed
}

private final class MockFileProviderDomainRepository: FileProviderDomainRepositoryProtocol, @unchecked Sendable {
    enum Message: Equatable {
        case addDomain
        case removeAllDomains
        case removeSyncData
        case signalErrorResolved(NSFileProviderError.Code)
    }

    static var newRepo: MockFileProviderDomainRepository {
        MockFileProviderDomainRepository(isReplicatedExtensionEnabled: false)
    }

    let isReplicatedExtensionEnabled: Bool
    private let error: (any Error)?
    private let failingErrorCode: NSFileProviderError.Code?
    private(set) var messages: [Message] = []

    /// - Parameters:
    ///   - error: What every call throws.
    ///   - failingErrorCode: The error whose signalling alone throws `MockError.failed`.
    init(isReplicatedExtensionEnabled: Bool, error: (any Error)? = nil, failingErrorCode: NSFileProviderError.Code? = nil) {
        self.isReplicatedExtensionEnabled = isReplicatedExtensionEnabled
        self.error = error
        self.failingErrorCode = failingErrorCode
    }

    func addDomain() async throws {
        messages.append(.addDomain)
        if let error { throw error }
    }

    func removeAllDomains() async throws {
        messages.append(.removeAllDomains)
        if let error { throw error }
    }

    func removeSyncData() async throws {
        messages.append(.removeSyncData)
        if let error { throw error }
    }

    func signalErrorResolved(_ error: NSFileProviderError) async throws {
        messages.append(.signalErrorResolved(error.code))
        if let error = self.error { throw error }
        if error.code == failingErrorCode { throw MockError.failed }
    }
}
