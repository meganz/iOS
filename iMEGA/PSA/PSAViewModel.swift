
enum PSAViewAction: ActionType {
    case showPSAViewIfNeeded
    case setPSAViewHidden(_ hide: Bool)
    case adjustPSAFrameIfNeeded
    case onViewReady
    case openPSAURLString(_ urlString: String)
    case dimiss(psaView: PSAView, psaEntity: PSAEntity)
}

@objc
final class PSAViewModel: NSObject, ViewModelType {
    
    private let router: PSAViewRouting
    private let useCase: PSAUseCase
    private var psaEntity: PSAEntity?
    
    @PreferenceWrapper(key: .lastPSAShownTimestamp, defaultValue: -1.0)
    private var lastPSAShownTimestampPreference: TimeInterval

    enum Command: CommandType, Equatable {
        case configView(PSAEntity)
    }
    
    var invokeCommand: ((Command) -> Void)?
        
    init(router: PSAViewRouting,
         useCase: PSAUseCase,
         preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.router = router
        self.useCase = useCase
        super.init()
        $lastPSAShownTimestampPreference.useCase = preferenceUseCase
    }
    
    func dispatch(_ action: PSAViewAction) {
        switch action {
        case .showPSAViewIfNeeded:
            guard router.isPSAViewAlreadyShown() == false else { return }
            shouldShowView { [weak self] show in
                guard let self = self, !self.router.isPSAViewAlreadyShown(), show else { return }
                
                self.router.start()
                self.router.currentPSAView()?.viewModel = self
            }
        case .setPSAViewHidden(let hide):
            router.hidePSAView(hide)
        case .adjustPSAFrameIfNeeded:
            router.adjustPSAViewFrame()
        case .onViewReady:
            lastPSAShownTimestampPreference = Date().timeIntervalSince1970
            invokeConfigViewCommandIfNeeded()
            getPSA()
        case .openPSAURLString(let urlString):
            router.openPSAURLString(urlString)
        case .dimiss(let psaView, let psaEntity):
            useCase.markAsSeenForPSA(withIdentifier: psaEntity.identifier)
            router.dismiss(psaView: psaView)
        }
    }
    
    // MARK: - Private methods.
    
    private func shouldShowView(completion: @escaping ((Bool) -> Void)) {
        // Avoid showing PSA if it is shown already within 1 hour (3600 seconds) time span.
        guard (lastPSAShownTimestampPreference <= 0
                || (Date().timeIntervalSince1970 - lastPSAShownTimestampPreference) >= 3600) else {
            MEGALogDebug("The PSA is already shown \(Date().timeIntervalSince1970 - lastPSAShownTimestampPreference) seconds back")
            completion(false)
            return
        }
        
        useCase.getPSA { [weak self] result in
            switch result {
            case .success(let psaEntity):
                self?.psaEntity = psaEntity
                if let URLString = psaEntity.URLString, !URLString.isEmpty {
                    self?.invokeConfigViewCommandIfNeeded()
                    completion(false)
                } else {
                    completion(true)
                }
            case .failure(_):
                completion(false)
            }
        }
    }
    
    private func getPSA() {
        useCase.getPSA { result in
            switch result {
            case .success(let psaEntity):
                guard self.psaEntity != psaEntity else {
                    return
                }
                self.psaEntity = psaEntity
                self.invokeConfigViewCommandIfNeeded()
            default:
                break
            }
        }
    }
    
    private func invokeConfigViewCommandIfNeeded() {
        guard let psaEntity = psaEntity else {
            return
        }
        
        if let URLString = psaEntity.URLString, !URLString.isEmpty {
            lastPSAShownTimestampPreference = Date().timeIntervalSince1970
            useCase.markAsSeenForPSA(withIdentifier: psaEntity.identifier)
            router.openPSAURLString(URLString)
        } else {
            invokeCommand?(.configView(psaEntity))
        }
    }
}
