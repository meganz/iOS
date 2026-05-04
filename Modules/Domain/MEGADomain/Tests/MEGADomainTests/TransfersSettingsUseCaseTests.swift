import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransfersSettingsUseCase Tests")
struct TransfersSettingsUseCaseTests {

    private static func makeSUT(
        maxConnectionsResult: Result<Int, any Error> = .success(4),
        setMaxConnectionsResult: Result<Void, any Error> = .success(())
    ) -> TransfersSettingsUseCase {
        let repo = MockTransfersSettingsRepository(
            maxConnectionsResult: maxConnectionsResult,
            setMaxConnectionsResult: setMaxConnectionsResult
        )
        return TransfersSettingsUseCase(repository: repo)
    }

    @Suite("maxDownloadConnections")
    struct MaxDownloadConnections {
        @Test("Returns value from repository")
        func returnsConnections() async throws {
            let sut = makeSUT(maxConnectionsResult: .success(6))
            #expect(try await sut.maxDownloadConnections() == 6)
        }

        @Test("Throws when repository fails")
        func throwsOnFailure() async {
            let sut = makeSUT(maxConnectionsResult: .failure(GenericErrorEntity()))
            await #expect(throws: GenericErrorEntity.self) {
                try await sut.maxDownloadConnections()
            }
        }
    }

    @Suite("maxUploadConnections")
    struct MaxUploadConnections {
        @Test("Returns value from repository")
        func returnsConnections() async throws {
            let sut = makeSUT(maxConnectionsResult: .success(2))
            #expect(try await sut.maxUploadConnections() == 2)
        }

        @Test("Throws when repository fails")
        func throwsOnFailure() async {
            let sut = makeSUT(maxConnectionsResult: .failure(GenericErrorEntity()))
            await #expect(throws: GenericErrorEntity.self) {
                try await sut.maxUploadConnections()
            }
        }
    }

    @Suite("setMaxDownloadConnections")
    struct SetMaxDownloadConnections {
        @Test("Completes without throwing")
        func succeeds() async throws {
            let sut = makeSUT()
            try await sut.setMaxDownloadConnections(5)
        }

        @Test("Throws when repository fails")
        func throwsOnFailure() async {
            let sut = makeSUT(setMaxConnectionsResult: .failure(GenericErrorEntity()))
            await #expect(throws: GenericErrorEntity.self) {
                try await sut.setMaxDownloadConnections(5)
            }
        }
    }

    @Suite("setMaxUploadConnections")
    struct SetMaxUploadConnections {
        @Test("Completes without throwing")
        func succeeds() async throws {
            let sut = makeSUT()
            try await sut.setMaxUploadConnections(3)
        }

        @Test("Throws when repository fails")
        func throwsOnFailure() async {
            let sut = makeSUT(setMaxConnectionsResult: .failure(GenericErrorEntity()))
            await #expect(throws: GenericErrorEntity.self) {
                try await sut.setMaxUploadConnections(3)
            }
        }
    }
}
