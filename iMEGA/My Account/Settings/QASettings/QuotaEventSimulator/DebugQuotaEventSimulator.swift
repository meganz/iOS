import MEGASdk
import UIKit

@MainActor
final class DebugQuotaEventSimulator {

    static let shared = DebugQuotaEventSimulator()

    private init() {}

    /// Storage scenarios. Raw values match the SDK `StorageState` codes read by
    /// `EventEntity+Mapper.mapCodeToStorageState` (0 green … 4 paywall).
    enum StorageScenario: Int, CaseIterable, Identifiable {
        case healthy = 0        // green
        case almostFull = 1     // orange
        case full = 2           // red
        case pendingChange = 3  // change
        case paywall = 4        // paywall → Over Disk Quota screen

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .healthy: "Storage healthy (green)"
            case .almostFull: "Storage almost full (orange modal)"
            case .full: "Storage full (red modal)"
            case .pendingChange: "Storage pending change (refetch)"
            case .paywall: "Storage paywall (ODQ screen)"
            }
        }
    }

    /// Transfer (bandwidth) over-quota scenarios — the OBQ dialog display modes.
    enum TransferScenario: Int, CaseIterable, Identifiable {
        case limitedDownload
        case downloadExceeded
        case streamingExceeded

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .limitedDownload: "Transfer quota – limited download"
            case .downloadExceeded: "Transfer quota – download exceeded"
            case .streamingExceeded: "Transfer quota – streaming exceeded"
            }
        }

        var displayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode {
            switch self {
            case .limitedDownload: .limitedDownload
            case .downloadExceeded: .downloadExceeded
            case .streamingExceeded: .streamingExceeded
            }
        }
    }

    /// A single selectable scenario across both storage and transfer paths (for the radio list).
    enum Scenario: Identifiable, Hashable {
        case storage(StorageScenario)
        case transfer(TransferScenario)

        static var allCases: [Scenario] {
            StorageScenario.allCases.map(Scenario.storage)
                + TransferScenario.allCases.map(Scenario.transfer)
        }

        var id: String {
            switch self {
            case .storage(let scenario): "storage-\(scenario.rawValue)"
            case .transfer(let scenario): "transfer-\(scenario.rawValue)"
            }
        }

        var title: String {
            switch self {
            case .storage(let scenario): scenario.title
            case .transfer(let scenario): scenario.title
            }
        }
    }

    /// The in-flight repeat run. Starting a new run cancels any previous one.
    private var runTask: Task<Void, Never>?

    /// Fires the selected scenario `count` times, waiting `interval` seconds before each send.
    /// The run is owned by this singleton, so it keeps firing after the QA page is dismissed.
    func start(_ scenario: Scenario, count: Int, interval: TimeInterval) {
        runTask?.cancel()
        runTask = Task { @MainActor in
            for _ in 0..<max(count, 1) {
                if interval > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
                if Task.isCancelled { return }
                self.fire(scenario)
            }
        }
    }

    /// Cancels any in-flight repeat run.
    func stop() {
        runTask?.cancel()
        runTask = nil
    }

    // MARK: - Private

    private func fire(_ scenario: Scenario) {
        switch scenario {
        case .storage(let scenario): fireStorageEvent(scenario)
        case .transfer(let scenario): fireTransferOverQuota(scenario)
        }
    }

    private func fireStorageEvent(_ scenario: StorageScenario) {
        guard let simulator = UIApplication.shared.delegate as? (any QAQuotaEventSimulating) else { return }
        simulator.qaSimulateStorageEvent(DebugStorageEvent(number: scenario.rawValue))
    }

    private func fireTransferOverQuota(_ scenario: TransferScenario) {
        QuotaWarningsRouter().presentTransferQuotaWarning(mode: scenario.displayMode)

        NotificationCenter.default.post(name: .MEGATransferOverQuota, object: nil)
    }
}

/// Minimal `MEGAEvent` subclass used only to synthesize storage events for QA simulation.
/// `onEvent` reads `type` and `number`, so those are the only members that need overriding.
private final class DebugStorageEvent: MEGAEvent, @unchecked Sendable {
    private let storageStateNumber: Int

    init(number: Int) {
        self.storageStateNumber = number
        super.init()
    }

    override var type: Event { .storage }
    override var number: Int { storageStateNumber }
}
