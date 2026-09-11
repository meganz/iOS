import Foundation
import MEGADomain
import MEGADomainMock
@testable import QuotaWarnings
import Testing

@Suite("TransferQuotaWarningMonitorTests")
struct TransferQuotaWarningMonitorTests {
    @Test("Starts monitoring every transfer quota activity")
    func startsEveryActivity() async {
        let download = MonitoringSpy()
        let streaming = MonitoringSpy()
        let sut = TransferQuotaWarningMonitor(useCases: [download, streaming])

        await sut.startMonitoring()

        #expect(download.monitorCallCount == 1)
        #expect(streaming.monitorCallCount == 1)
    }

    /// Neither activity ends on its own, so the app target's task is what ends monitoring.
    @Test("Stops monitoring when the owning task is cancelled")
    func stopsWhenCancelled() async {
        let download = MonitoringSpy(runsUntilCancelled: true)
        let streaming = MonitoringSpy(runsUntilCancelled: true)
        let sut = TransferQuotaWarningMonitor(useCases: [download, streaming])

        let task = Task { await sut.startMonitoring() }
        while download.monitorCallCount == 0 || streaming.monitorCallCount == 0 {
            await Task.yield()
        }
        task.cancel()

        await task.value

        #expect(download.monitorCallCount == 1)
        #expect(streaming.monitorCallCount == 1)
    }
}

/// Stands in for one activity's trigger, recording that it was asked to monitor. `runsUntilCancelled`
/// mirrors production, where the state sequence only ends with the task watching it.
private final class MonitoringSpy: TransferAlmostFullDialogUseCaseProtocol, @unchecked Sendable {
    private let runsUntilCancelled: Bool
    private let lock = NSLock()
    private var callCount = 0

    var monitorCallCount: Int {
        lock.withLock { callCount }
    }

    init(runsUntilCancelled: Bool = false) {
        self.runsUntilCancelled = runsUntilCancelled
    }

    func monitorTransferQuotaState() async {
        lock.withLock { callCount += 1 }
        guard runsUntilCancelled else { return }
        while !Task.isCancelled {
            await Task.yield()
        }
    }
}
