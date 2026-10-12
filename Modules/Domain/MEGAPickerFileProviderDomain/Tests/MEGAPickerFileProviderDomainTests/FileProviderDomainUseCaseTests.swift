import MEGAPickerFileProviderDomain
import Testing

struct FileProviderDomainUseCaseTests {
    @Test
    func registerDomain_whenReplicatedExtensionIsEnabled_addsDomain() async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: true)
        let sut = FileProviderDomainUseCase(repository: repository)

        try await sut.registerDomain()

        #expect(repository.messages == [.addDomain])
    }

    @Test
    func registerDomain_whenReplicatedExtensionIsDisabled_removesAllDomainsAndTheSyncData() async throws {
        let repository = MockFileProviderDomainRepository(isReplicatedExtensionEnabled: false)
        let sut = FileProviderDomainUseCase(repository: repository)

        try await sut.registerDomain()

        #expect(repository.messages == [.removeAllDomains, .removeSyncData])
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
    }

    static var newRepo: MockFileProviderDomainRepository {
        MockFileProviderDomainRepository(isReplicatedExtensionEnabled: false)
    }

    let isReplicatedExtensionEnabled: Bool
    private let error: (any Error)?
    private(set) var messages: [Message] = []

    init(isReplicatedExtensionEnabled: Bool, error: (any Error)? = nil) {
        self.isReplicatedExtensionEnabled = isReplicatedExtensionEnabled
        self.error = error
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
}
