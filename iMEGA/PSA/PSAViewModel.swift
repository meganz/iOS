
enum PSAViewAction: ActionType {
    case onViewReady
    case dismiss(PSAEntity)
}

@objc
final class PSAViewModel: NSObject, ViewModelType {
    
    private let router: PSAViewRouter
    private let useCase: PSAUseCase
    private var psaEntity: PSAEntity?
    
    @PreferenceWrapper(key: .lastPSAShownTimestamp, defaultValue: -1.0)
    private var lastPSAShownTimestampPreference: TimeInterval

    enum Command: CommandType, Equatable {
        case configView(PSAEntity)
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(router: PSAViewRouter,
         useCase: PSAUseCase,
         preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.router = router
        self.useCase = useCase
        super.init()
        $lastPSAShownTimestampPreference.useCase = preferenceUseCase
    }
    
    func dispatch(_ action: PSAViewAction) {
        switch action {
        case .onViewReady:
            lastPSAShownTimestampPreference = Date().timeIntervalSince1970
            invokeConfigViewCommandIfNeeded()
            getPSA()
        case .dismiss(let entity):
            useCase.setPSA(withIdentifier: entity.identifier)
        }
    }
    
    func shouldShowView(completion: @escaping ((Bool) -> Void)) {
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
            dispatch(.dismiss(psaEntity))
            router.openPSAURLString(URLString)
        } else {
            invokeCommand?(.configView(psaEntity))
        }
    }
}
