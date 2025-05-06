import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPreference

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
    private let router: any AddPhoneNumberRouting
    private let achievementUseCase: any AchievementUseCaseProtocol
    private let hideDontShowAgain: Bool

    @PreferenceWrapper(key: PreferenceKeyEntity.dontShowAgainAddPhoneNumber, defaultValue: false)
    private var dontShowAddPhoneNumberPreference: Bool

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some AddPhoneNumberRouting,
         achievementUseCase: any AchievementUseCaseProtocol,
         preferenceUseCase: any PreferenceUseCaseProtocol = PreferenceUseCase.default,
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
        Task { @MainActor [weak self] in
            do {
                guard let storage = try await self?.achievementUseCase.getAchievementStorage(by: .addPhone) else { return }
                let storageText = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(String.memoryStyleString(fromByteCount: storage.valueNumber.int64Value))
                self?.invokeCommand?(.showAchievementStorage(storageText))
            } catch {
                self?.invokeCommand?(.loadAchievementError(message: Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA))
            }

        }
    }
}
