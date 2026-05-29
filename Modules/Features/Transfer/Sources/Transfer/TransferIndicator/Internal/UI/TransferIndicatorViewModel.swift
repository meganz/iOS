import Combine
import MEGADomain
import SwiftUI

@MainActor
final class TransferIndicatorViewModel: ObservableObject {
    @Published public private(set) var state: TransferIndicatorViewState = .initial
    @Published public private(set) var isVisible = false

    private let useCase: any TransferIndicatorUseCaseProtocol
    private let viewStateMapper: any TransferIndicatorViewStateMapping
    private var cancellable: AnyCancellable?
    private var monitoringTask: Task<Void, Never>?
    private var completedDismissTask: Task<Void, Never>?
    private var isMonitoring = false

    public init(
        useCase: some TransferIndicatorUseCaseProtocol,
        viewStateMapper: some TransferIndicatorViewStateMapping = TransferIndicatorViewStateMapper()
    ) {
        self.useCase = useCase
        self.viewStateMapper = viewStateMapper
    }

    deinit {
        monitoringTask?.cancel()
        completedDismissTask?.cancel()
    }

    /// Starts observing the shared transfer indicator source of truth.
    ///
    /// The ViewModel is intentionally passive: it reads the latest available value and
    /// maps incoming entities into renderable UI state without owning reset/dismiss logic.
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        apply(entity: useCase.currentState)
        cancellable = useCase.statePublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] entity in
                self?.apply(entity: entity)
            }
        monitoringTask = Task { [useCase] in
            await useCase.startMonitoring()
        }
    }

    /// Applies the latest domain entity to the UI-facing indicator state.
    private func apply(entity: TransferIndicatorEntity) {
        guard entity != .hidden else {
            cancelCompletedDismiss()
            isVisible = false
            state = .initial
            return
        }

        let mappedState = viewStateMapper.map(entity)
        if case .completed = mappedState {
            scheduleCompletedDismiss()
        } else {
            cancelCompletedDismiss()
        }

        state = mappedState
        isVisible = true
    }

    /// Owns the completed auto-dismiss lifecycle for the shared presentation state.
    private func scheduleCompletedDismiss() {
        completedDismissTask?.cancel()
        let useCase = useCase
        completedDismissTask = Task { [useCase] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await useCase.clearTerminalState()
        }
    }

    private func cancelCompletedDismiss() {
        completedDismissTask?.cancel()
        completedDismissTask = nil
    }
}
