import MEGAAppPresentation
import MEGADomain
import MEGAPreference

enum BannerContainerViewAction: ActionType {
    case onViewWillAppear
    case onViewDidLoad(UITraitCollection)
    case onTraitCollectionDidChange(UITraitCollection)
    case onClose
}

protocol BannerContainerViewRouting: Routing {}

final class BannerContainerViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable {
        case configureView(message: String, backgroundColor: UIColor, textColor: UIColor, actionIcon: UIImage?)
        case showBanner(animated: Bool)
        case hideBanner(animated: Bool)
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var message: String
    private var type: BannerType
    
    @PreferenceWrapper(key: PreferenceKeyEntity.offlineLogOutWarningDismissed, defaultValue: false)
    private var offlineLogOutWarningDismissed: Bool
    
    init(
         message: String,
         type: BannerType,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.message = message
        self.type = type
        $offlineLogOutWarningDismissed.useCase = preferenceUseCase
    }
    
    private func configureView(traitCollection: UITraitCollection) {
        switch traitCollection.userInterfaceStyle {
        case .dark:
            invokeCommand?(.configureView(message: message, backgroundColor: type.darkBgColor, textColor: type.darkTextColor, actionIcon: type.actionIcon))
        default:
            invokeCommand?(.configureView(message: message, backgroundColor: type.bgColor, textColor: type.textColor, actionIcon: type.actionIcon))
        }
    }
    
    func dispatch(_ action: BannerContainerViewAction) {
        switch action {
        case .onViewWillAppear:
            if offlineLogOutWarningDismissed {
                invokeCommand?(.hideBanner(animated: false))
            }
        case .onViewDidLoad(let traitCollection):
            if !offlineLogOutWarningDismissed {
                configureView(traitCollection: traitCollection)
            }
        case .onTraitCollectionDidChange(let traitCollection):
            configureView(traitCollection: traitCollection)
        case .onClose:
            offlineLogOutWarningDismissed = true
            invokeCommand?(.hideBanner(animated: true))
        }
    }
}
