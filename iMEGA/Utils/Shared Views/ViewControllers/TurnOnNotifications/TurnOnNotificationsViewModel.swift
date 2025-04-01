import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n

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
    private let router: any TurnOnNotificationsViewRouting
    
    @PreferenceWrapper(key: .lastDateTurnOnNotificationsShowed, defaultValue: Date.init(timeIntervalSince1970: 0))
    private var lastDateTurnOnNotificationsShowedPreference: Date
    
    @PreferenceWrapper(key: .timesTurnOnNotificationsShowed, defaultValue: 0)
    private var timesTurnOnNotificationsShowedPreference: Int
    
    private let accountUseCase: any AccountUseCaseProtocol
        
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some TurnOnNotificationsViewRouting,
         preferenceUseCase: any PreferenceUseCaseProtocol = PreferenceUseCase.default,
         accountUseCase: any AccountUseCaseProtocol) {
        self.router = router
        self.accountUseCase = accountUseCase
        $lastDateTurnOnNotificationsShowedPreference.useCase = preferenceUseCase
        $timesTurnOnNotificationsShowedPreference.useCase = preferenceUseCase
    }
    
    func shouldShowTurnOnNotifications() -> Bool {
        guard let days = Calendar.current.dateComponents([.day], from: lastDateTurnOnNotificationsShowedPreference, to: Date()).day else {
            return false
        }
        if timesTurnOnNotificationsShowedPreference < 3 && days > 7
            && accountUseCase.isLoggedIn() {
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
            
            let title = Strings.Localizable.Dialog.TurnOnNotifications.Label.title
            let description = Strings.Localizable.Dialog.TurnOnNotifications.Label.description
            let stepOne = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepOne
            let stepTwo = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepTwo
            let stepThree = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepThree
            let stepFour = Strings.Localizable.Dialog.TurnOnNotifications.Label.stepFour
            
            let notificationsModel = TurnOnNotificationsModel(headerImage: UIImage.groupChat,
                                                              title: title,
                                                              description: description,
                                                              stepOneImage: UIImage.openSettings,
                                                              stepOne: stepOne,
                                                              stepTwoImage: UIImage.tapNotifications,
                                                              stepTwo: stepTwo,
                                                              stepThreeImage: UIImage.tapMega,
                                                              stepThree: stepThree,
                                                              stepFourImage: UIImage.allowNotifications,
                                                              stepFour: stepFour,
                                                              openSettingsTitle: Strings.Localizable.Dialog.TurnOnNotifications.Button.primary,
                                                              dismissTitle: Strings.Localizable.dismiss)
            invokeCommand?(.configView(notificationsModel))
        case .dismiss:
            router.dismiss()
        case .openSettings:
            router.openSettings()
        }
    }
}
