import MEGADomain
import MEGADomainMock
import Testing

@Suite("Call to enable/disable request status monitor use case test suite")
struct RequestStatusMonitorUseCaseTests {
    @Test("Enable/disable request status monitor", arguments: [true, false])
    func enableRequestStatusMonitor(_ enabled: Bool) {
        let sut = RequestStatusMonitorUseCase(repo: MockRequestStatusMonitorRepository.newRepo)
        sut.enableRequestStatusMonitor(enabled)
        if enabled {
            #expect(sut.isRequestStatusMonitorEnabled(), "Expected request status monitor to be enabled")
        } else {
            #expect(!sut.isRequestStatusMonitorEnabled(), "Expected request status monitor to be disabled")
        }
    }
}
