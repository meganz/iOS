import MEGADomain
import MEGAPresentation

enum FileVersioningViewAction: ActionType {
    case onViewLoaded
    case enableFileVersions
    case disableFileVersions
    case deletePreviousVersions
}

protocol FileVersioningViewRouting: Routing {
    func showDisableAlert(completion: @escaping (Bool) -> Void)
    func showDeletePreviousVersionsAlert(completion: @escaping (Bool) -> Void)
}

final class LegacyFileVersioningViewModel: ViewModelType {
    
    private let fileVersionsUseCase: any FileVersionsUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    
    enum Command: CommandType, Equatable {
        case updateSwitch(Bool)
        case updateFileVersions(Int64)
        case updateFileVersionsSize(Int64)
    } 
    // MARK: - Private properties
    private let router: any FileVersioningViewRouting
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some FileVersioningViewRouting,
         fileVersionsUseCase: any FileVersionsUseCaseProtocol,
         accountUseCase: any AccountUseCaseProtocol) {
        self.router = router
        self.fileVersionsUseCase = fileVersionsUseCase
        self.accountUseCase = accountUseCase
    }
    
    func dispatch(_ action: FileVersioningViewAction) {
        switch action {
        case .onViewLoaded:
            viewLoaded()
            
        case .enableFileVersions:
            enableFileVersions(true)
            
        case .disableFileVersions:
            disableFileVersions()
                        
        case .deletePreviousVersions:
            deletePreviousVersions()
        }
    }
    
    // MARK: - Private
    
    private func viewLoaded() {
        Task {
            do {
                let value = try await fileVersionsUseCase.isFileVersionsEnabled()
                invokeCommand?(.updateSwitch(value))
            } catch {
                guard let error = error as? FileVersionErrorEntity, error == .optionNeverSet else { return }
                invokeCommand?(.updateSwitch(true))
            }
            
#if MAIN_APP_TARGET
            invokeCommand?(.updateFileVersions(fileVersionsUseCase.rootNodeFileVersionCount()))
            invokeCommand?(.updateFileVersionsSize(fileVersionsUseCase.rootNodeFileVersionTotalSizeInBytes()))
#endif
        }
    }
    
    private func disableFileVersions() {
        router.showDisableAlert { [weak self] disable in
            if disable {
                self?.enableFileVersions(false)
            } else {
                self?.invokeCommand?(.updateSwitch(true))
            }
        }
    }
    
    private func enableFileVersions(_ enable: Bool) {
        Task {
            guard let enabled = try? await fileVersionsUseCase.enableFileVersions(enable) else { return }
            invokeCommand?(.updateSwitch(enabled))
        }
    }
    
    private func deletePreviousVersions() {
        router.showDeletePreviousVersionsAlert { [weak self] delete in
            guard delete, let self else { return }
            
            Task {
                guard ((try? await self.fileVersionsUseCase.deletePreviousFileVersions()) != nil) else { return }
                self.updateFileVersion()
            }
        }
    }
    
    private func updateFileVersion() {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.accountUseCase.refreshCurrentAccountDetails()
    #if MAIN_APP_TARGET
                self.invokeCommand?(.updateFileVersions(self.fileVersionsUseCase.rootNodeFileVersionCount()))
    #endif
                self.invokeCommand?(.updateFileVersionsSize(self.fileVersionsUseCase.rootNodeFileVersionTotalSizeInBytes()))
            } catch {
                MEGALogError("[File versioning] Error loading account details. Error: \(error)")
            }
        }
    }
}
