import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import PhoneNumberKit

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

@MainActor
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
    private let achievementUseCase: any AchievementUseCaseProtocol
    private let authUseCase: any AuthUseCaseProtocol
    private var regionList = [SMSRegion]()
    var selectedRegion: SMSRegion?
    private let router: any SMSVerificationViewRouting
    
    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some SMSVerificationViewRouting,
         smsUseCase: SMSUseCase,
         achievementUseCase: any AchievementUseCaseProtocol,
         authUseCase: any AuthUseCaseProtocol,
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
                Task {
                    await getAchievementStorage()
                }
            }
        case .loadRegionCodes:
            Task {
                await loadCallingCodes()
            }
        case .showRegionList:
            router.goToRegionList(regionList) { [weak self] in
                self?.setSelectedRegion($0)
                self?.showRegion($0)
            }
        case .sendCodeToPhoneNumber(let number, let regionCode):
            Task {
                await sendCodeToPhoneNumber(number, regionCode: regionCode)
            }
        case .logout:
            authUseCase.logout()
        case .cancel:
            router.dismiss()
        }
    }
    
    // MARK: - Load regions
    private func loadCallingCodes() async {
        invokeCommand?(.startLoading)
        do {
            let codes = try await smsUseCase.getSMSUseCase.getRegionCallingCodes()
            regionList = codes.allRegions.compactMap { $0.toSMSRegion() }
            if let region = codes.currentRegion?.toSMSRegion() {
                setSelectedRegion(region)
                showRegion(region)
            }
        } catch {
            MEGALogError("Could not load country calling code with error \(error)")
        }
        invokeCommand?(.finishLoading)
    }
    
    // MARK: - Show a region
    private func setSelectedRegion(_ region: SMSRegion) {
        selectedRegion = region
    }
    
    private func showRegion(_ region: SMSRegion) {
        invokeCommand?(.showRegion(region.displayName, callingCode: region.displayCallingCode))
    }

    // MARK: - Get achievement
    private func getAchievementStorage() async {
        do {
            let storage = try await achievementUseCase.getAchievementStorage(by: .addPhone)
            let message = Strings.Localizable.GetFreeWhenYouAddYourPhoneNumber.thisMakesItEasierForYourContactsToFindYouOnMEGA(String.memoryStyleString(fromByteCount: storage.valueNumber.int64Value))
            invokeCommand?(.showLoadAchievementResult(.showStorage(message)))
        } catch {
            let message = Strings.Localizable.AddYourPhoneNumberToMEGA.thisMakesItEasierForYourContactsToFindYouOnMEGA
            invokeCommand?(.showLoadAchievementResult(.showError(message)))
        }
    }
    
    // MARK: - Send code
    private func sendCodeToPhoneNumber(
        _ phoneNumber: String,
        regionCode: RegionCode
    ) async {
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

        await sendVerificationCode(formattedNumber)
        invokeCommand?(.finishLoading)
    }
    
    private func sendVerificationCode(_ code: String) async {
        do {
            let number = try await smsUseCase.checkSMSUseCase.sendVerification(toPhoneNumber: code)
            router.goToVerificationCode(forPhoneNumber: number, withRegionCode: code)
        } catch let error as CheckSMSErrorEntity {
            let message = switch error {
            case .reachedDailyLimit: Strings.Localizable.youHaveReachedTheDailyLimit
            case .alreadyVerifiedWithCurrentAccount: Strings.Localizable.yourAccountIsAlreadyVerified
            case .alreadyVerifiedWithAnotherAccount: Strings.Localizable.thisNumberIsAlreadyAssociatedWithAMegaAccount
            default: Strings.Localizable.unknownError
            }
            invokeCommand?(.sendCodeToPhoneNumberError(message: message))
        } catch {
            invokeCommand?(.sendCodeToPhoneNumberError(message: Strings.Localizable.unknownError))
        }
    }
}
