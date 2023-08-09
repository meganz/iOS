import Combine
import MEGADomain
import MEGAPresentation

enum OfflineViewAction: ActionType {
    case addSubscriptions
    case removeSubscriptions
}

final class OfflineViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadUI
    }
    
    var invokeCommand: ((Command) -> Void)?
    private let transferUseCase: any NodeTransferUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Init
    init(transferUseCase: some NodeTransferUseCaseProtocol) {
        self.transferUseCase = transferUseCase
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: OfflineViewAction) {
        switch action {
        case .addSubscriptions:
            registerTransferDelegates()
        case .removeSubscriptions:
            deRegisterTransferDelegates()
        }
    }
    
    // MARK: - Subscriptions
    
    private func registerTransferDelegates() {
        Task { [weak self] in
            guard let self else { return }
            await transferUseCase.registerMEGATransferDelegate()
            await transferUseCase.registerMEGASharedFolderTransferDelegate()
            setUpSubscription()
        }
    }
    
    private func deRegisterTransferDelegates() {
        Task.detached { [weak self] in
            guard let self else { return }
            await transferUseCase.deRegisterMEGATransferDelegate()
            await transferUseCase.deRegisterMEGASharedFolderTransferDelegate()
            subscriptions.removeAll()
        }
    }
    
    private func setUpSubscription() {
        transferUseCase.transferResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                handleTransferResult(result)
            }
            .store(in: &subscriptions)
    }
    
    private func handleTransferResult(_ result: Result<TransferEntity, TransferErrorEntity>) {
        guard case .success(let request) = result,
              request.type == .download else {
            return
        }
        invokeCommand?(.reloadUI)
    }
}
