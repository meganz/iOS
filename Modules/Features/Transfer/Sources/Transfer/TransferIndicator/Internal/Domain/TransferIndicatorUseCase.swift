@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGAPreference

protocol TransferIndicatorUseCaseProtocol: AnyObject, Sendable {
    var currentState: TransferIndicatorEntity { get }
    var statePublisher: AnyPublisher<TransferIndicatorEntity, Never> { get }
    func startMonitoring() async
    func clearTerminalState() async
}

final class TransferIndicatorUseCase: TransferIndicatorUseCaseProtocol {
    private let transferCounterUseCase: any TransferCounterUseCaseProtocol
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let preferenceUseCase: any PreferenceUseCaseProtocol
    private let hasPendingUploads: @Sendable () -> Bool
    private let tracker = TransferProgressTracker()
    private let stateSubject = CurrentValueSubject<TransferIndicatorEntity, Never>(.hidden)

    public var currentState: TransferIndicatorEntity {
        stateSubject.value
    }

    public var statePublisher: AnyPublisher<TransferIndicatorEntity, Never> {
        stateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public init(
        transferCounterUseCase: some TransferCounterUseCaseProtocol,
        transferInventoryUseCase: some TransferInventoryUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol,
        hasPendingUploads: @escaping @Sendable () -> Bool = { false }
    ) {
        self.transferCounterUseCase = transferCounterUseCase
        self.transferInventoryUseCase = transferInventoryUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.preferenceUseCase = preferenceUseCase
        self.hasPendingUploads = hasPendingUploads
    }
    /// Runs the long-lived monitoring flow that keeps the latest transfer indicator
    /// state in sync with transfer, storage, and pause updates.
    ///
    /// The use case owns the latest state and publishes it through `statePublisher`,
    /// so multiple screens can observe the same source of truth passively.
    public func startMonitoring() async {
        let transferCounterUseCase = transferCounterUseCase
        let transferInventoryUseCase = transferInventoryUseCase
        let accountStorageUseCase = accountStorageUseCase
        let preferenceUseCase = preferenceUseCase
        let hasPendingUploads = hasPendingUploads
        let tracker = tracker
        let stateSubject = stateSubject

        let publishLatestState: @Sendable () async -> Void = {
            let transfers = await transferInventoryUseCase.transfers(filteringUserTransfers: true)
            await tracker.initializeIfNeeded(with: transfers)
            let isPaused: Bool = preferenceUseCase[PreferenceKeyEntity.transfersPaused.rawValue] ?? false
            let entity = Self.makeEntity(
                from: await tracker.snapshot(
                    isGloballyPaused: isPaused,
                    hasPendingUploads: hasPendingUploads()
                )
            )
            stateSubject.send(entity)
        }

        let transfers = await transferInventoryUseCase.transfers(filteringUserTransfers: true)
        await tracker.initializeIfNeeded(with: transfers)

        await publishLatestState()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await transfer in transferCounterUseCase.transferStartUpdates {
                    guard !Task.isCancelled else { return }
                    await tracker.handleTransferStart(transfer)
                    await publishLatestState()
                }
            }

            group.addTask {
                for await transfer in transferCounterUseCase.transferUpdates {
                    guard !Task.isCancelled else { return }
                    await tracker.upsert(transfer)
                    await publishLatestState()
                }
            }

            group.addTask {
                for await response in transferCounterUseCase.transferTemporaryErrorUpdates {
                    guard !Task.isCancelled else { return }
                    await tracker.trackTemporaryError(response)
                    await tracker.upsert(response.transferEntity)
                    await publishLatestState()
                }
            }

            group.addTask {
                for await response in transferCounterUseCase.transferFinishUpdates {
                    guard !Task.isCancelled else { return }
                    await tracker.trackFinish(response.transferEntity)
                    await tracker.remove(tag: response.transferEntity.tag)
                    await publishLatestState()
                }
            }

            group.addTask {
                for await storageStatus in accountStorageUseCase.onStorageStatusUpdates {
                    guard !Task.isCancelled else { return }
                    if storageStatus == .noStorageProblems {
                        await tracker.clearOverquota()
                        await publishLatestState()
                    }
                }
            }

            group.addTask { [preferenceUseCase] in
                var lastPausedState: Bool = preferenceUseCase[PreferenceKeyEntity.transfersPaused.rawValue] ?? false
                for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                    guard !Task.isCancelled else { return }
                    let isPaused: Bool = preferenceUseCase[PreferenceKeyEntity.transfersPaused.rawValue] ?? false
                    guard isPaused != lastPausedState else { continue }
                    lastPausedState = isPaused
                    await publishLatestState()
                }
            }

            await group.waitForAll()
        }
    }

    /// Recomputes the latest domain entity from the tracker and pushes it to subscribers.
    ///
    /// This method is called after every tracker mutation so the published value always
    /// reflects the newest aggregate transfer state.
    private func publishLatestState() async {
        let transfers = await transferInventoryUseCase.transfers(filteringUserTransfers: true)
        await tracker.initializeIfNeeded(with: transfers)
        let isPaused: Bool = preferenceUseCase[PreferenceKeyEntity.transfersPaused.rawValue] ?? false
        let entity = Self.makeEntity(
            from: await tracker.snapshot(
                isGloballyPaused: isPaused,
                hasPendingUploads: hasPendingUploads()
            )
        )
        stateSubject.send(entity)
    }

    /// Converts the internal aggregate tracker snapshot into the externally visible
    /// transfer indicator entity consumed by presentation.
    private static func makeEntity(from snapshot: TransferStatusSnapshot?) -> TransferIndicatorEntity {
        guard let snapshot else {
            return .hidden
        }

        if snapshot.hasError {
            return .error
        } else if snapshot.hasOverquota {
            return .warning
        } else if snapshot.isPaused {
            return .paused(progress: snapshot.progress)
        } else if snapshot.isCompleted {
            return .completed
        } else {
            return .inProgress(progress: snapshot.progress)
        }
    }

    /// Clears the current terminal batch state after presentation has consumed it.
    public func clearTerminalState() async {
        await tracker.clearTerminalState()
        await publishLatestState()
    }
}
