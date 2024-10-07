import MEGADomain
import MEGAPresentation

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
            shouldShowView { [weak self] show in
                guard let self = self, !self.router.isPSAViewAlreadyShown(), show else { return }
                
                self.router.start()
                self.router.currentPSAView()?.viewModel = self
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
    
    // MARK: - Private methods.
    
    private func shouldShowView(completion: @escaping ((Bool) -> Void)) {
        // Avoid showing PSA if it is shown already within 1 hour (3600 seconds) time span.
        guard lastPSARequestTimestampPreference <= 0
                || (Date().timeIntervalSince1970 - lastPSARequestTimestampPreference) >= 3600 else {
            MEGALogDebug("PSA is already fetched \(Date().timeIntervalSince1970 - lastPSARequestTimestampPreference) seconds back")
            completion(false)
            return
        }
        
        lastPSARequestTimestampPreference = Date().timeIntervalSince1970
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
            case .failure:
                completion(false)
            }
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
