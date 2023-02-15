import Foundation
import MEGADomain
import MEGAPresentation

enum AddPhoneNumberAction: ActionType {
    case onViewReady
    case addPhoneNumber
    case notNow
    case notShowAddPhoneNumberAgain
}

protocol AddPhoneNumberRouting: Routing {
    func dismiss()
    func goToVerification()
}

final class AddPhoneNumberViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(hideDontShowAgain: Bool)
        case showAchievementStorage(String)
        case loadAchievementError(message: String)
    }
    
    // MARK: - Private properties
    private let router: AddPhoneNumberRouting
    private let achievementUseCase: AchievementUseCaseProtocol
    private let hideDontShowAgain: Bool

    @PreferenceWrapper(key: .dontShowAgainAddPhoneNumber, defaultValue: false)
    private var dontShowAddPhoneNumberPreference: Bool

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: AddPhoneNumberRouting,
         achievementUseCase: AchievementUseCaseProtocol,
         preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
         hideDontShowAgain: Bool) {
        self.router = router
        self.achievementUseCase = achievementUseCase
        self.hideDontShowAgain = hideDontShowAgain
        $dontShowAddPhoneNumberPreference.useCase = preferenceUseCase
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: AddPhoneNumberAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(hideDontShowAgain: hideDontShowAgain))
            getAchievementStorage()
        case .notShowAddPhoneNumberAgain:
            dontShowAddPhoneNumberPreference = true
            router.dismiss()
        case .notNow:
            router.dismiss()
        case .addPhoneNumber:
            router.goToVerification()
        }
    }
    
    // MARK: - Get achievement storage
    private func getAchievementStorage() {
        achievementUseCase.getAchievementStorage(by: .addPhone) { [weak self] in
            switch $0 {
            case .success(let storage):
                let storageText = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(Helper.memoryStyleString(fromByteCount: storage.valueNumber.int64Value))
                self?.invokeCommand?(.showAchievementStorage(storageText))
            case .failure:
                self?.invokeCommand?(.loadAchievementError(message: Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA))
            }
        }
    }
}
