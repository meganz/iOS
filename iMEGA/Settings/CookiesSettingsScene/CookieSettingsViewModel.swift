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
    case preferenceCookiesSwitchValueChanged(Bool)
    case performanceAndAnalyticsSwitchValueChanged(Bool)
    case advertisingCookiesSwitchValueChanged(Bool)
    case thirdPartyCookiesSwitchValueChanged(Bool)
    
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
    
    private let cookieSettingsUseCase: CookieSettingsUseCase
    private let router: CookieSettingsRouter
    
    var invokeCommand: ((Command) -> Void)?
    
    private var cookiesConfigArray: Array<Bool> = [true, false, false, false, false] //[essential, preference, analytics, ads, thirdparty]
    private var currentCookiesConfigArray: Array<Bool> = [true, false, false, false, false]
    
    // MARK: - Init
    
    init(cookieSettingsUseCase: CookieSettingsUseCase, router: CookieSettingsRouter) {
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
            
        case .preferenceCookiesSwitchValueChanged(let bool):
            cookiesConfigArray[CookiesBitPosition.preference.rawValue] = bool
            
        case .performanceAndAnalyticsSwitchValueChanged(let bool):
            cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue] = bool
            
        case .advertisingCookiesSwitchValueChanged(let bool):
            cookiesConfigArray[CookiesBitPosition.advertising.rawValue] = bool
            
        case .thirdPartyCookiesSwitchValueChanged(let bool):
            cookiesConfigArray[CookiesBitPosition.thirdParty.rawValue] = bool
            
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
        footersArray.append(NSLocalizedString("Essential for providing you important functionality and secure access to our services. For this reason, they do not require consent.", comment: ""))
        footersArray.append(NSLocalizedString("Allow us to remember certain display and formatting settings you choose. Not accepting these Cookies will mean we won’t be able to remember some things for you such as your preferred screen layout.", comment: ""))
        footersArray.append(NSLocalizedString("Help us to understand how you use our services and provide us data that we can use to make improvements. Not accepting these Cookies will mean we will have less data available to us to help design improvements.", comment: ""))
        footersArray.append(NSLocalizedString("Used by us and our approved advertising partners to customise the adverts you see on our services and on other websites based on your browsing history. Not accepting these Cookies means we may show advertisements that are less relevant.", comment: ""))
        footersArray.append(NSLocalizedString("These are Cookies which are controlled by someone other than us; we use these Cookies to provide the types of functionality described above. Not accepting these Cookies will have different implications depending on what type of Cookie each third party Cookie is. Click on ‘More Information’ below for details on all the third party Cookies we use.", comment: "Cookie settings dialog text."))
        
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
        for (index, value) in currentCookiesConfigArray.enumerated() {
            if cookiesConfigArray[index] != value {
                return true
            }
        }
        
        return false
    }
}
