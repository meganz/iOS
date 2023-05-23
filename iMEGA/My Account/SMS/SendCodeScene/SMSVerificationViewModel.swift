import Foundation
import MEGADomain
import PhoneNumberKit
import MEGAPresentation

enum SMSVerificationAction: ActionType {
    case onViewReady
    case loadRegionCodes
    case logout
    case showRegionList
    case sendCodeToPhoneNumber(String, regionCode: RegionCode)
    case cancel
}

protocol SMSVerificationViewRouting: Routing {
    func dismiss()
    func goToRegionList(_ list: [SMSRegion], onRegionSelected: @escaping (SMSRegion) -> Void)
    func goToVerificationCode(forPhoneNumber number: String, withRegionCode: RegionCode)
}

final class SMSVerificationViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case startLoading
        case finishLoading
        case configView(SMSVerificationType)
        case showRegion(String, callingCode: String)
        case showLoadAchievementResult(LoadAchievementResultCommand)
        case sendCodeToPhoneNumberError(message: String)
        
        enum LoadAchievementResultCommand: Equatable {
            case showStorage(String)
            case showError(String)
        }
    }
    
    // MARK: - Private properties
    private let verificationType: SMSVerificationType
    private let smsUseCase: SMSUseCase
    private let achievementUseCase: AchievementUseCaseProtocol
    private let authUseCase: AuthUseCaseProtocol
    private var regionList = [SMSRegion]()
    var selectedRegion: SMSRegion? = nil
    private let router: SMSVerificationViewRouting
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: SMSVerificationViewRouting,
         smsUseCase: SMSUseCase,
         achievementUseCase: AchievementUseCaseProtocol,
         authUseCase: AuthUseCaseProtocol,
         verificationType: SMSVerificationType = .unblockAccount) {
        self.router = router
        self.smsUseCase = smsUseCase
        self.achievementUseCase = achievementUseCase
        self.authUseCase = authUseCase
        self.verificationType = verificationType
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: SMSVerificationAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.configView(verificationType))
            if case SMSVerificationType.addPhoneNumber = verificationType {
                getAchievementStorage()
            }
        case .loadRegionCodes:
            loadCallingCodes()
        case .showRegionList:
            router.goToRegionList(regionList) { [weak self] in
                self?.setSelectedRegion($0)
                self?.showRegion($0)
            }
        case .sendCodeToPhoneNumber(let number, let regionCode):
            sendCodeToPhoneNumber(number, regionCode: regionCode)
        case .logout:
            authUseCase.logout()
        case .cancel:
            router.dismiss()
        }
    }
    
    // MARK: - Load regions
    private func loadCallingCodes() {
        invokeCommand?(.startLoading)
        smsUseCase.getSMSUseCase.getRegionCallingCodes { [weak self] in
            guard let self = self else { return }
            
            self.invokeCommand?(.finishLoading)
            switch $0 {
            case .success(let codes):
                self.regionList = codes.allRegions.compactMap { $0.toSMSRegion() }
                if let region = codes.currentRegion?.toSMSRegion() {
                    self.setSelectedRegion(region)
                    self.showRegion(region)
                }
            case .failure(let error):
                MEGALogError("Could not load country calling code with error \(error)")
            }
        }
    }
    
    // MARK: - Show a region
    private func setSelectedRegion(_ region: SMSRegion) {
        selectedRegion = region
    }
    
    private func showRegion(_ region: SMSRegion) {
        invokeCommand?(.showRegion(region.displayName, callingCode: region.displayCallingCode))
    }

    // MARK: - Get achievement
    private func getAchievementStorage() {
        Task { @MainActor  [weak self] in
            do {
                guard let storage = try await self?.achievementUseCase.getAchievementStorage(by: .addPhone) else { return }
                let message = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(String.memoryStyleString(fromByteCount: storage.valueNumber.int64Value))
                self?.invokeCommand?(.showLoadAchievementResult(.showStorage(message)))
            } catch {
                let message = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
                self?.invokeCommand?(.showLoadAchievementResult(.showError(message)))
            }
        }
    }
    
    // MARK: - Send code
    private func sendCodeToPhoneNumber(_ phoneNumber: String, regionCode: RegionCode) {
        invokeCommand?(.startLoading)
        let formattedNumber: String
        do {
            let numberKit = PhoneNumberKit()
            let parsedNumber = try numberKit.parse(phoneNumber, withRegion: regionCode)
            formattedNumber = numberKit.format(parsedNumber, toType: .e164)
        } catch {
            let message = Strings.Localizable.pleaseEnterAValidPhoneNumber
            invokeCommand?(.finishLoading)
            invokeCommand?(.sendCodeToPhoneNumberError(message: message))
            return
        }
        smsUseCase.checkSMSUseCase.sendVerification(toPhoneNumber: formattedNumber) { [weak self] in
            self?.invokeCommand?(.finishLoading)
            switch $0 {
            case .success(let number):
                DispatchQueue.main.async { self?.router.goToVerificationCode(forPhoneNumber: number, withRegionCode: regionCode) }
            case .failure(let error):
                let message: String
                switch error {
                case .reachedDailyLimit:
                    message = Strings.Localizable.youHaveReachedTheDailyLimit
                case .alreadyVerifiedWithCurrentAccount:
                    message = Strings.Localizable.yourAccountIsAlreadyVerified
                case .alreadyVerifiedWithAnotherAccount:
                    message = Strings.Localizable.thisNumberIsAlreadyAssociatedWithAMegaAccount
                default:
                    message = Strings.Localizable.unknownError
                }
                
                self?.invokeCommand?(.sendCodeToPhoneNumberError(message: message))
            }
        }
    }
}
