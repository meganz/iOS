@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

@Suite("TransfersSettingsRepository Tests")
struct TransfersSettingsRepositoryTests {

    private static func makeSUT(
        requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1))
    ) -> TransfersSettingsRepository {
        TransfersSettingsRepository(sdk: MockSdk(requestResult: requestResult))
    }

    @Suite("maxConnections")
    struct MaxConnections {
        @Test("Returns connection count from request number for download", arguments: [3, 4, 8])
        func returnsDownloadConnections(expected: Int) async throws {
            let sut = makeSUT(requestResult: .success(MockRequest(handle: 1, number: Int64(expected))))

            let result = try await sut.maxConnections(for: .download)

            #expect(result == expected)
        }

        @Test("Returns connection count from request number for upload", arguments: [1, 3, 6])
        func returnsUploadConnections(expected: Int) async throws {
            let sut = makeSUT(requestResult: .success(MockRequest(handle: 1, number: Int64(expected))))

            let result = try await sut.maxConnections(for: .upload)

            #expect(result == expected)
        }

        @Test("Throws when SDK returns error")
        func throwsOnError() async {
            let sut = makeSUT(requestResult: .failure(MockError.failingError))

            await #expect(throws: (any Error).self) {
                try await sut.maxConnections(for: .download)
            }
        }
    }

    @Suite("setMaxConnections")
    struct SetMaxConnections {
        @Test("Completes without throwing for download")
        func setsDownloadConnections() async throws {
            let sut = makeSUT()
            try await sut.setMaxConnections(5, for: .download)
        }

        @Test("Completes without throwing for upload")
        func setsUploadConnections() async throws {
            let sut = makeSUT()
            try await sut.setMaxConnections(3, for: .upload)
        }

        @Test("Throws when SDK returns error")
        func throwsOnError() async {
            let sut = makeSUT(requestResult: .failure(MockError.failingError))

            await #expect(throws: (any Error).self) {
                try await sut.setMaxConnections(5, for: .download)
            }
        }
    }
}
