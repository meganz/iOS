import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation

enum CookiesBitPosition: Int {
    case essential
    case preference
    case performanceAndAnalytics
    case advertising
    case thirdParty
}

struct CookiesBitmap: OptionSet, Hashable {
    let rawValue: Int
    
    static let essential = CookiesBitmap(rawValue: 1 << 0)      // 1 bit
    static let preference = CookiesBitmap(rawValue: 1 << 1)     // 2 bit
    static let analytics = CookiesBitmap(rawValue: 1 << 2)      // 4 bit
    static let ads = CookiesBitmap(rawValue: 1 << 3)            // 8 bit
    static let thirdparty = CookiesBitmap(rawValue: 1 << 4)     // 16 bit
    static let adsCheckCookie = CookiesBitmap(rawValue: 1 << 5) // 32 bit
    
    static let all: CookiesBitmap = [.essential, .preference, .analytics, .ads, .thirdparty]
}

struct Cookie {
    let name: CookiesBitmap
    var value: Bool
}

enum CookieSettingsAction: ActionType {
    case configView
    
    case acceptCookiesSwitchValueChanged(Bool)
    case performanceAndAnalyticsSwitchValueChanged(Bool)
    case advertisingSwitchValueChanged(Bool)
    
    case showCookiePolicy
    
    case save
}

@MainActor
final class CookieSettingsViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configCookieSettings(CookiesBitmap)
        
        case updateFooters(Array<String>)
            
        case cookieSettingsSaved
        
        case showSnackBar(String)
        
        case showResult(ResultCommand)
        enum ResultCommand: Equatable {
            case success(String)
            case error(String)
        }
    }
    
    enum SectionType {
        case externalAdsActive, externalAdsInactive

        var numberOfSections: Int {
            switch self {
            case .externalAdsActive: return 4
            case .externalAdsInactive: return 3
            }
        }
    }
    
    private let accountUseCase: any AccountUseCaseProtocol
    private let cookieSettingsUseCase: any CookieSettingsUseCaseProtocol
    private let router: any CookieSettingsRouting
    private var abTestProvider: any ABTestProviderProtocol
    
    var invokeCommand: ((Command) -> Void)?
    
    private var cookiesConfigArray: [Cookie] = .default
    private var currentCookiesConfigArray: [Cookie] = .default
    private var cookieSettingsSet: Bool = true
    private(set) var numberOfSection: Int = 0
    private(set) var isExternalAdsActive: Bool = false
    
    private(set) var configViewTask: Task<Void, Never>?
    private(set) var showCookiePolicyURLTask: Task<Void, Never>?
    
    private let cookieSettingToPosition: [CookiesBitmap: CookiesBitPosition] = [
        .essential: .essential,
        .preference: .preference,
        .analytics: .performanceAndAnalytics,
        .ads: .advertising,
        .thirdparty: .thirdParty
    ]
    
    // MARK: - Init
    
    init(
        accountUseCase: some AccountUseCaseProtocol,
        cookieSettingsUseCase: some CookieSettingsUseCaseProtocol,
        router: some CookieSettingsRouting,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider
    ) {
        self.accountUseCase = accountUseCase
        self.cookieSettingsUseCase = cookieSettingsUseCase
        self.router = router
        self.abTestProvider = abTestProvider
    }
    
    deinit {
        configViewTask?.cancel()
        configViewTask = nil
        showCookiePolicyURLTask?.cancel()
        showCookiePolicyURLTask = nil
    }
        
    func dispatch(_ action: CookieSettingsAction) {
        switch action {
        case .configView:
            configViewTask = Task {
                await setUpExternalAds()
                await cookieSettings()
                setNumberOfSections()
                setFooters()
            }
            
        case .acceptCookiesSwitchValueChanged(let isOn):
            cookiesConfigArray = isOn ? .allTrue : .default
            
        case .performanceAndAnalyticsSwitchValueChanged(let isOn):
            cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue].value = isOn
            
        case .advertisingSwitchValueChanged(let isOn):
            guard isExternalAdsActive else { return }
            cookiesConfigArray[CookiesBitPosition.advertising.rawValue].value = isOn
            
        case .showCookiePolicy:
            showCookiePolicyURL()

        case .save:
            save()
        }
    }
    
    // MARK: - Ads Cookie Flags
    private func setUpExternalAds() async {
        let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
        let isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
        isExternalAdsActive = isAdsEnabled && isExternalAdsEnabled
    }
    
    // MARK: - Cookie policy
    private func showCookiePolicyURL() {
        guard let cookiePolicyURL = URL(string: "https://mega.nz/cookie") else { return }
        
        guard isExternalAdsActive else {
            self.router.didTap(on: .showCookiePolicy(url: cookiePolicyURL))
            return
        }
        
        showCookiePolicyURLTask = Task {
            do {
                let cookiePath = cookiePolicyURL.lastPathComponent
                let sessionTransferURL = try await self.accountUseCase.sessionTransferURL(path: cookiePath)
                self.router.didTap(on: .showCookiePolicy(url: sessionTransferURL))
            } catch {
                self.invokeCommand?(.showSnackBar(Strings.Localizable.somethingWentWrong))
            }
        }
    }
    
    // MARK: - Private
    
    private func cookieSettings() async {
        do {
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            var cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            
            if cookiesBitmap != .essential {
                for (setting, position) in cookieSettingToPosition where cookiesBitmap.contains(setting) {
                    cookiesConfigArray[position.rawValue].value = true
                }
            }
            
            // From Cookie Dialog with Ads
            if isExternalAdsActive,
               cookiesBitmap.contains(.ads),
               !cookiesBitmap.contains(.adsCheckCookie) {
                // Remove ads cookie value
                cookiesConfigArray[CookiesBitPosition.advertising.rawValue].value = false
                cookiesBitmap.remove(.ads)
            }
            currentCookiesConfigArray = cookiesConfigArray
            
            invokeCommand?(.configCookieSettings(cookiesBitmap))
            
        } catch {
            guard let cookieSettingsError = error as? CookieSettingsErrorEntity else {
                return
            }
            
            switch cookieSettingsError {
            case .generic, .invalidBitmap: break
                
            case .bitmapNotSet:
                cookieSettingsSet = false
                cookiesConfigArray = .default
                currentCookiesConfigArray = cookiesConfigArray
                invokeCommand?(.configCookieSettings(CookiesBitmap.essential))
            }
        }
    }
    
    private func setFooters() {
        var footersArray: [String] = []
        
        footersArray.append(Strings.Localizable.Settings.Accept.Cookies.footer)
        footersArray.append(Strings.Localizable.Settings.Cookies.Essential.footer)
        footersArray.append(Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer)
        
        if isExternalAdsActive {
            footersArray.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        }
        
        self.invokeCommand?(.updateFooters(footersArray))
    }
    
    private func setNumberOfSections() {
        numberOfSection = isExternalAdsActive ? SectionType.externalAdsActive.numberOfSections : SectionType.externalAdsInactive.numberOfSections
    }
    
    private func save() {
        if !didCookieSettingsChange() {
            self.invokeCommand?(.cookieSettingsSaved)
            return
        }
        
        Task {
            do {
                var cookiesBitmap = CookiesBitmap(rawValue: 0)
                cookiesBitmap.insert(.essential)
                
                for (setting, position) in cookieSettingToPosition where cookiesConfigArray[position.rawValue].value {
                    cookiesBitmap.insert(setting)
                }
                
                if isExternalAdsActive {
                    cookiesBitmap.insert(.adsCheckCookie)
                }
                
                _ = try await cookieSettingsUseCase.setCookieSettings(with: cookiesBitmap.rawValue)
                invokeCommand?(.cookieSettingsSaved)
            } catch {
                guard let error = error as? CookieSettingsErrorEntity else {
                    invokeCommand?(.showResult(.error(error.localizedDescription)))
                    return
                }
                switch error {
                case .invalidBitmap:
                    invokeCommand?(.showResult(.error(error.localizedDescription)))
                    
                default:
                    invokeCommand?(.showResult(.error(error.localizedDescription)))
                }
            }
        }
    }
    
    private func didCookieSettingsChange() -> Bool {
        if !cookieSettingsSet {
            return true
        }
        
        for (index, cookie) in currentCookiesConfigArray.enumerated() where cookiesConfigArray[index].value != cookie.value {
            return true
        }
        
        return false
    }
}

private extension Array where Element == Cookie {
    
    static let `default`: [Cookie] = [
        Cookie(name: .essential, value: true),
        Cookie(name: .preference, value: false),
        Cookie(name: .analytics, value: false),
        Cookie(name: .ads, value: false),
        Cookie(name: .thirdparty, value: false)
    ]
    
    static var allTrue: [Cookie] {
        `default`.map { Cookie(name: $0.name, value: true) }
    }
}
