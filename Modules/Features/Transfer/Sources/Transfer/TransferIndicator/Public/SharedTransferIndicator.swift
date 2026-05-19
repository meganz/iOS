@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo

@MainActor
public enum SharedTransferIndicator {
    private static var configuredViewModel: TransferIndicatorViewModel?
    private static var configuredUseCase: (any TransferIndicatorUseCaseProtocol)?

    /// Marks whether the currently stored view model is only a temporary fallback
    /// created before the shared indicator is properly configured. This allows
    /// `configure()` to later replace it with the real implementation.
    private static var isFallback = false

    /// Whether `configure()` has been called with a real use case.
    public static var isConfigured: Bool { configuredViewModel != nil && !isFallback }

    static var useCase: (any TransferIndicatorUseCaseProtocol)? {
        if configuredUseCase == nil {
            assertionFailure("SharedTransferIndicator.useCase accessed before configure() was called.")
        }
        return configuredUseCase
    }

    /// Shared Transfer Indicator ViewModel consumed across screens.
    ///
    /// The concrete dependency graph is configured by the app target so this package
    /// can stay free of app-only composition details.
    static var viewModel: TransferIndicatorViewModel {
        if let configuredViewModel {
            return configuredViewModel
        }

        assertionFailure("SharedTransferIndicator must be configured before use.")
        let fallbackUseCase = HiddenTransferIndicatorUseCase()
        let fallback = TransferIndicatorViewModel(useCase: fallbackUseCase)
        configuredUseCase = fallbackUseCase
        configuredViewModel = fallback
        isFallback = true
        return fallback
    }

    /// Current visibility snapshot. Returns `false` when not yet configured.
    public static var isCurrentlyVisible: Bool {
        guard isConfigured else { return false }
        return viewModel.isVisible
    }

    /// Publisher that emits whether the transfer indicator should be visible.
    /// Returns `nil` when not yet configured — callers should skip subscription.
    public static var isVisiblePublisher: AnyPublisher<Bool, Never>? {
        guard isConfigured else { return nil }
        return viewModel.$isVisible.eraseToAnyPublisher()
    }

    /// Configures the shared transfer indicator, injecting only the pieces that
    /// still need app-side knowledge while keeping the rest of the setup in-package.
    ///
    /// Safe to call even if an early fallback was created — will replace it.
    public static func configure(hasPendingUploads: @escaping @Sendable () -> Bool) {
        guard !isConfigured else { return }

        let useCase = TransferIndicatorUseCase(
            transferCounterUseCase: TransferCounterUseCase(
                repo: NodeTransferRepository.newRepo,
                transferInventoryRepository: TransferInventoryRepository.newRepo,
                fileSystemRepository: FileSystemRepository.sharedRepo
            ),
            transferInventoryUseCase: TransferInventoryUseCase(
                transferInventoryRepository: TransferInventoryRepository.newRepo,
                fileSystemRepository: FileSystemRepository.sharedRepo
            ),
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default
            ),
            preferenceUseCase: PreferenceUseCase.default,
            hasPendingUploads: hasPendingUploads
        )
        configuredUseCase = useCase

        let viewModel = TransferIndicatorViewModel(useCase: useCase)
        viewModel.startMonitoring()
        configuredViewModel = viewModel
        isFallback = false
    }
}

private final class HiddenTransferIndicatorUseCase: TransferIndicatorUseCaseProtocol, Sendable {
    var currentState: TransferIndicatorEntity { .hidden }

    var statePublisher: AnyPublisher<TransferIndicatorEntity, Never> {
        Just(.hidden).eraseToAnyPublisher()
    }

    var snapshotPublisher: AnyPublisher<TransferStatusSnapshot?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func startMonitoring() async {}

    func clearTerminalState() async {}
}
