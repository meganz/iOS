@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo

@MainActor
public enum SharedTransferIndicator {
    private static var configuredViewModel: TransferIndicatorViewModel?

    /// Shared Transfer Indicator ViewModel consumed across screens.
    ///
    /// The concrete dependency graph is configured by the app target so this package
    /// can stay free of app-only composition details.
    static var viewModel: TransferIndicatorViewModel {
        if let configuredViewModel {
            return configuredViewModel
        }

        assertionFailure("SharedTransferIndicator must be configured before use.")
        let fallback = TransferIndicatorViewModel(useCase: HiddenTransferIndicatorUseCase())
        configuredViewModel = fallback
        return fallback
    }

    /// Configures the shared transfer indicator once, injecting only the pieces that
    /// still need app-side knowledge while keeping the rest of the setup in-package.
    ///
    /// The shared ViewModel and its monitoring lifecycle stay encapsulated within the
    /// package, so callers only need to invoke this one-time setup entry point.
    public static func configure(hasPendingUploads: @escaping @Sendable () -> Bool) {
        guard configuredViewModel == nil else { return }

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

        let viewModel = TransferIndicatorViewModel(useCase: useCase)
        viewModel.startMonitoring()
        configuredViewModel = viewModel
    }
}

private final class HiddenTransferIndicatorUseCase: TransferIndicatorUseCaseProtocol, Sendable {
    var currentState: TransferIndicatorEntity { .hidden }

    var statePublisher: AnyPublisher<TransferIndicatorEntity, Never> {
        Just(.hidden).eraseToAnyPublisher()
    }

    func startMonitoring() async {}

    func clearTerminalState() async {}
}
