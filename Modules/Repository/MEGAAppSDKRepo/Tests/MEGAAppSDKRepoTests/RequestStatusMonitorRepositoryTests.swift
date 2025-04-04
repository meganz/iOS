import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import Testing

@Suite("Call to enable/disable request status monitor repository test suite")
struct RequestStatusMonitorRepositoryTests {
    @Test("Enable/disable request status monitor", arguments: [true, false])
    func enableRequestStatusMonitor(_ enabled: Bool) {
        let sut = RequestStatusMonitorRepository(sdk: MockSdk())
        sut.enableRequestStatusMonitor(enabled)
        if enabled {
            #expect(sut.isRequestStatusMonitorEnabled(), "Expected request status monitor to be enabled")
        } else {
            #expect(!sut.isRequestStatusMonitorEnabled(), "Expected request status monitor to be disabled")
        }
    }
}
