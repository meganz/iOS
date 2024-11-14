import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import Testing

@Suite("Event provider suite tests")
struct EventProviderTests {
    @Test("On event sequence creation should add global delegate and remove when terminated")
    func testEvent() async throws {
        let sdk = MockSdk()
        let sut = EventProvider(sdk: sdk)
        let task = Task {
            for await _ in sut.event {}
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(sdk.hasGlobalDelegate)
        task.cancel()
        #expect(!sdk.hasGlobalDelegate)
    }
}
