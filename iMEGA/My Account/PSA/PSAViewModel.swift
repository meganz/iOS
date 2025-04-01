import MEGAAppPresentation
import MEGADomain

enum PSAViewAction: ActionType {
    case showPSAViewIfNeeded
    case setPSAViewHidden(_ hide: Bool)
    case onViewReady
    case openPSAURLString(_ urlString: String)
    case dimiss(psaView: PSAView, psaEntity: PSAEntity)
}

@objc
final class PSAViewModel: NSObject, ViewModelType {
    
    private let router: any PSAViewRouting
    private let useCase: any PSAUseCaseProtocol
    private var psaEntity: PSAEntity?
    
    @PreferenceWrapper(key: .lastPSARequestTimestamp, defaultValue: -1.0)
    private var lastPSARequestTimestampPreference: TimeInterval
    
    private(set) var currentTask: Task<Void, Never>?
    
    enum Command: CommandType, Equatable {
        case configView(PSAEntity)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(router: some PSAViewRouting,
         useCase: some PSAUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.router = router
        self.useCase = useCase
        super.init()
        $lastPSARequestTimestampPreference.useCase = preferenceUseCase
    }
    
    func dispatch(_ action: PSAViewAction) {
        switch action {
        case .showPSAViewIfNeeded:
            guard router.isPSAViewAlreadyShown() == false else { return }
            
            currentTask?.cancel()
            currentTask = Task {
                let shouldShowView = await shouldShowView()
                
                guard router.isPSAViewAlreadyShown() == false, shouldShowView else { return }
                
                router.start()
                router.currentPSAView()?.viewModel = self
            }
        case .setPSAViewHidden(let hide):
            router.hidePSAView(hide)
        case .onViewReady:
            invokeConfigViewCommandIfNeeded()
        case .openPSAURLString(let urlString):
            router.openPSAURLString(urlString)
        case .dimiss(let psaView, let psaEntity):
            useCase.markAsSeenForPSA(withIdentifier: psaEntity.identifier)
            router.dismiss(psaView: psaView)
        }
    }
    
    // MARK: - Private methods
    @MainActor
    private func shouldShowView() async -> Bool {
        guard lastPSARequestTimestampPreference <= 0
                || (Date().timeIntervalSince1970 - lastPSARequestTimestampPreference) >= 3600 else {
            MEGALogDebug("PSA is already fetched \(Date().timeIntervalSince1970 - lastPSARequestTimestampPreference) seconds back")
            return false
        }
        
        lastPSARequestTimestampPreference = Date().timeIntervalSince1970
        
        do {
            psaEntity = try await useCase.getPSA()
            if let URLString = psaEntity?.URLString, !URLString.isEmpty {
                invokeConfigViewCommandIfNeeded()
                return false
            } else {
                return true
            }
        } catch {
            return false
        }
    }
    
    private func invokeConfigViewCommandIfNeeded() {
        guard let psaEntity = psaEntity else {
            MEGALogDebug("PSA entity was not found")
            return
        }
        
        if let URLString = psaEntity.URLString, !URLString.isEmpty {
            useCase.markAsSeenForPSA(withIdentifier: psaEntity.identifier)
            router.openPSAURLString(URLString)
        } else {
            invokeCommand?(.configView(psaEntity))
        }
    }
}
