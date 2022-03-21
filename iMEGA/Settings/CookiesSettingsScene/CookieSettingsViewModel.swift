import Foundation

enum CookiesBitPosition: Int {
    case essential
    case preference
    case performanceAndAnalytics
    case advertising
    case thirdParty
}

struct CookiesBitmap: OptionSet {
    let rawValue: Int
    
    static let essential = CookiesBitmap(rawValue: 1 << 0)
    static let preference = CookiesBitmap(rawValue: 1 << 1)
    static let analytics = CookiesBitmap(rawValue: 1 << 2)
    static let ads = CookiesBitmap(rawValue: 1 << 3)
    static let thirdparty = CookiesBitmap(rawValue: 1 << 4)
    
    static let all: CookiesBitmap = [.essential, .preference, .analytics, .ads, .thirdparty]
}

enum CookieSettingsAction: ActionType {
    case configView
    
    case acceptCookiesSwitchValueChanged(Bool)
    case performanceAndAnalyticsSwitchValueChanged(Bool)
    
    case save
}

final class CookieSettingsViewModel: NSObject, ViewModelType {
    enum Command: CommandType {
        case configCookieSettings(CookiesBitmap)
        
        case updateFooters(Array<String>)
            
        case cookieSettingsSaved
        
        case showResult(ResultCommand)
        enum ResultCommand: Equatable {
            case success(String)
            case error(String)
        }
    }
    
    private let cookieSettingsUseCase: CookieSettingsUseCaseProtocol
    private let router: CookieSettingsRouter
    
    var invokeCommand: ((Command) -> Void)?
    
    private var cookiesConfigArray: Array<Bool> = [true, false, false, false, false] //[essential, preference, analytics, ads, thirdparty]
    private var currentCookiesConfigArray: Array<Bool> = [true, false, false, false, false]
    private var cookieSettingsSet: Bool = true
    
    // MARK: - Init
    
    init(cookieSettingsUseCase: CookieSettingsUseCaseProtocol, router: CookieSettingsRouter) {
        self.cookieSettingsUseCase = cookieSettingsUseCase
        self.router = router
    }
        
    func dispatch(_ action: CookieSettingsAction) {
        switch action {
        case .configView:
            cookieSettings()
            setFooters()
            
        case .acceptCookiesSwitchValueChanged(let bool):
            cookiesConfigArray = bool ? [true, true, true, true, true] : [true, false, false, false, false]
            
        case .performanceAndAnalyticsSwitchValueChanged(let bool):
            cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue] = bool
            cookieSettingsUseCase.setAnalyticsEnabled(bool)
        case .save:
            save()
        }
    }
    
    // MARK: - Private
    
    private func cookieSettings() {
        cookieSettingsUseCase.cookieSettings { [weak self] in
            switch $0 {
            case .success(let bitmap):
                let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
                if cookiesBitmap.contains(.preference) {
                    self?.cookiesConfigArray[CookiesBitPosition.preference.rawValue] = true
                }
                if cookiesBitmap.contains(.analytics) {
                    self?.cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue] = true
                }
                if cookiesBitmap.contains(.ads) {
                    self?.cookiesConfigArray[CookiesBitPosition.advertising.rawValue] = true
                }
                if cookiesBitmap.contains(.thirdparty) {
                    self?.cookiesConfigArray[CookiesBitPosition.thirdParty.rawValue] = true
                }
                self?.currentCookiesConfigArray = self!.cookiesConfigArray
                
                self?.invokeCommand?(.configCookieSettings(CookiesBitmap(rawValue: bitmap)))
                
            case .failure(let error):
                switch error {
                case .generic, .invalidBitmap: break
                    
                case .bitmapNotSet:
                    self?.cookieSettingsSet = false
                    self?.cookiesConfigArray = [true, false, false, false, false]
                    self?.currentCookiesConfigArray = self!.cookiesConfigArray
                    self?.invokeCommand?(.configCookieSettings(CookiesBitmap.essential))
                }
            }
        }
    }
    
    private func setFooters() {
        var footersArray: Array<String> = []
        
        footersArray.append("")
        footersArray.append(Strings.Localizable.Settings.Cookies.Essential.footer)
        footersArray.append(Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer)
        
        self.invokeCommand?(.updateFooters(footersArray))
    }
    
    private func save() {
        if !didCookieSettingsChange() {
            self.invokeCommand?(.cookieSettingsSaved)
            return
        }
        
        var cookiesBitmap = CookiesBitmap(rawValue: 0)
        cookiesBitmap.insert(.essential)
        if cookiesConfigArray[CookiesBitPosition.preference.rawValue] {
            cookiesBitmap.insert(.preference)
        }
        if cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue] {
            cookiesBitmap.insert(.analytics)
        }
        if cookiesConfigArray[CookiesBitPosition.advertising.rawValue] {
            cookiesBitmap.insert(.ads)
        }
        if cookiesConfigArray[CookiesBitPosition.thirdParty.rawValue] {
            cookiesBitmap.insert(.thirdparty)
        }
        
        cookieSettingsUseCase.setCookieSettings(with: cookiesBitmap.rawValue) { [weak self] in
            switch $0 {
            case .success(_):
                self?.invokeCommand?(.cookieSettingsSaved)
                
            case .failure(let error):
                switch error {
                case .invalidBitmap:
                    self?.invokeCommand?(.showResult(.error(error.localizedDescription)))
                    
                default:
                    self?.invokeCommand?(.showResult(.error(error.localizedDescription)))
                }
            }
        }
    }
    
    private func didCookieSettingsChange() -> Bool {
        if !cookieSettingsSet {
            return true
        }
        
        for (index, value) in currentCookiesConfigArray.enumerated() {
            if cookiesConfigArray[index] != value {
                return true
            }
        }
        
        return false
    }
}
