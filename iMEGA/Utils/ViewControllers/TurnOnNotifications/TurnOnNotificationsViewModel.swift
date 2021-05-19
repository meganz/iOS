
import Foundation

enum TurnOnNotificationsViewAction: ActionType {
    case onViewLoaded
    case dismiss
    case openSettings
}

protocol TurnOnNotificationsViewRouting: Routing {
    func dismiss()
    func openSettings()
}

final class TurnOnNotificationsViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(TurnOnNotificationsModel)
    }
    
    // MARK: - Private properties
    private let router: TurnOnNotificationsViewRouting
    
    @PreferenceWrapper(key: .lastDateTurnOnNotificationsShowed, defaultValue: Date.init(timeIntervalSince1970: 0))
    private var lastDateTurnOnNotificationsShowedPreference: Date
    
    @PreferenceWrapper(key: .timesTurnOnNotificationsShowed, defaultValue: 0)
    private var timesTurnOnNotificationsShowedPreference: Int
    
    private let authUseCase: AuthUseCaseProtocol
        
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: TurnOnNotificationsViewRouting,
         preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
         authUseCase: AuthUseCaseProtocol) {
        self.router = router
        self.authUseCase = authUseCase
        $lastDateTurnOnNotificationsShowedPreference.useCase = preferenceUseCase
        $timesTurnOnNotificationsShowedPreference.useCase = preferenceUseCase
    }
    
    func shouldShowTurnOnNotifications() -> Bool {
        guard let days = Calendar.current.dateComponents([.day], from: lastDateTurnOnNotificationsShowedPreference, to: Date()).day else {
            return false
        }
        if timesTurnOnNotificationsShowedPreference < 3 && days > 7
            && authUseCase.isLoggedIn() {
            return true
        }
        return false
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: TurnOnNotificationsViewAction) {
        switch action {
        case .onViewLoaded:
            lastDateTurnOnNotificationsShowedPreference = Date()
            timesTurnOnNotificationsShowedPreference += 1
            
            let title = NSLocalizedString("dialog.turnOnNotifications.label.title", comment: "The title of Turn on Notifications view")
            let description = NSLocalizedString("dialog.turnOnNotifications.label.description", comment: "The description of Turn on Notifications view")
            let stepOne = NSLocalizedString("dialog.turnOnNotifications.label.stepOne", comment: "First step to turn on notifications")
            let stepTwo = NSLocalizedString("dialog.turnOnNotifications.label.stepTwo", comment: "Second step to turn on notifications")
            let stepThree = NSLocalizedString("dialog.turnOnNotifications.label.stepThree", comment: "Third step to turn on notifications")
            
            let notificationsModel = TurnOnNotificationsModel(headerImageName: "groupChat",
                                                              title: title,
                                                              description: description,
                                                              stepOneImageName: "openSettings",
                                                              stepOne: stepOne,
                                                              stepTwoImageName: "tapNotifications",
                                                              stepTwo: stepTwo,
                                                              stepThreeImageName: "allowNotifications",
                                                              stepThree: stepThree,
                                                              openSettingsTitle: NSLocalizedString("dialog.turnOnNotifications.button.primary", comment: "Title of the button to open Settings"),
                                                              dismissTitle: NSLocalizedString("dismiss", comment: ""))
            invokeCommand?(.configView(notificationsModel))
        case .dismiss:
            router.dismiss()
        case .openSettings:
            router.openSettings()
        }
    }
}
