import Foundation
import MEGADomain
import MEGASwift

/// App-lifetime recorder of transfer finish instants, configured at launch
/// alongside `SharedTransferIndicator`.
///
/// The Completed tab needs the moment each transfer finished, but the SDK
/// snapshot carries no usable wall-clock timestamp (`MEGATransfer.updateTime` has
/// no defined epoch). This recorder subscribes to transfer finish events from
/// launch and stamps `Date()` per finishing tag, so a row already has its date by
/// the time the Transfers screen is first opened — including transfers that
/// finished before it was opened. It mirrors the lifetime of the SDK's in-memory
/// completed list: entries are removed when the matching completed-transfer row
/// is cleared, and both stores reset at relaunch, so nothing is persisted.
///
/// `TransferCounterUseCase.transferFinishUpdates` is a sufficient source: its
/// `isValidTransfer` filter is a superset of the user-transfer filter the tabs
/// apply, so every row the tabs can render is covered.
///
/// `@unchecked Sendable`: all mutable state is protected by `@Atomic`.
public final class SharedTransferFinishRecorder: @unchecked Sendable {
    public static let shared = SharedTransferFinishRecorder()

    private let counterUseCase: any TransferCounterUseCaseProtocol
    @Atomic private var datesByTag: [Int: Date] = [:]
    @Atomic private var monitorTask: Task<Void, Never>?

    init(counterUseCase: some TransferCounterUseCaseProtocol = DependencyInjection.transferCounterUseCase) {
        self.counterUseCase = counterUseCase
    }

    deinit {
        monitorTask?.cancel()
    }

    /// Starts recording finish instants. Safe to call more than once; only the
    /// first call starts the monitor.
    public func configure() {
        guard monitorTask == nil else { return }

        // Intentionally app-lifetime for the shared recorder: the stream is
        // non-terminating, matching the lifetime of the SDK completed list it annotates.
        let task = Task { [weak self, counterUseCase] in
            for await response in counterUseCase.transferFinishUpdates {
                self?.recordCompletedFinish(response.transferEntity)
            }
        }

        var shouldCancelTask = false
        $monitorTask.mutate { monitorTask in
            if monitorTask == nil {
                monitorTask = task
            } else {
                shouldCancelTask = true
            }
        }

        if shouldCancelTask {
            task.cancel()
        }
    }

    package func recordCompletedFinish(_ entity: TransferEntity) {
        guard entity.state == .complete else { return }
        recordIfAbsent(tag: entity.tag, date: Date())
    }
}

extension SharedTransferFinishRecorder: TransferFinishDateProviding {
    package func finishDate(forTag tag: Int) -> Date? {
        datesByTag[tag]
    }

    @discardableResult
    package func recordIfAbsent(tag: Int, date: Date) -> Date {
        var effectiveDate = date
        $datesByTag.mutate { datesByTag in
            if let existingDate = datesByTag[tag] {
                effectiveDate = existingDate
            } else {
                datesByTag[tag] = date
            }
        }
        return effectiveDate
    }

    package func removeDates(forTags tags: Set<Int>) {
        guard !tags.isEmpty else { return }

        $datesByTag.mutate { datesByTag in
            tags.forEach { datesByTag.removeValue(forKey: $0) }
        }
    }
}
