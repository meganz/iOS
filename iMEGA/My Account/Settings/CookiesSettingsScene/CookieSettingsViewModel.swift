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
    
    static let essential = CookiesBitmap(rawValue: 1 << 0)
    static let preference = CookiesBitmap(rawValue: 1 << 1)
    static let analytics = CookiesBitmap(rawValue: 1 << 2)
    static let ads = CookiesBitmap(rawValue: 1 << 3)
    static let thirdparty = CookiesBitmap(rawValue: 1 << 4)
    
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
    
    case save
}

final class CookieSettingsViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case configCookieSettings(CookiesBitmap)
        
        case updateFooters(Array<String>)
            
        case cookieSettingsSaved
        
        case showResult(ResultCommand)
        enum ResultCommand: Equatable {
            case success(String)
            case error(String)
        }
    }
    
    private let cookieSettingsUseCase: any CookieSettingsUseCaseProtocol
    private let router: any CookieSettingsRouting
    
    var invokeCommand: ((Command) -> Void)?
    
    private var cookiesConfigArray: [Cookie] = .default
    private var currentCookiesConfigArray: [Cookie] = .default
    private var cookieSettingsSet: Bool = true
    
    private let cookieSettingToPosition: [CookiesBitmap: CookiesBitPosition] = [
        .essential: .essential,
        .preference: .preference,
        .analytics: .performanceAndAnalytics,
        .ads: .advertising,
        .thirdparty: .thirdParty
    ]
    
    // MARK: - Init
    
    init(cookieSettingsUseCase: any CookieSettingsUseCaseProtocol, router: some CookieSettingsRouting) {
        self.cookieSettingsUseCase = cookieSettingsUseCase
        self.router = router
    }
        
    func dispatch(_ action: CookieSettingsAction) {
        switch action {
        case .configView:
            Task { @MainActor in
                await cookieSettings()
                setFooters()
            }
            
        case .acceptCookiesSwitchValueChanged(let isOn):
            cookiesConfigArray = isOn ? .allTrue : .default
            
        case .performanceAndAnalyticsSwitchValueChanged(let isOn):
            cookiesConfigArray[CookiesBitPosition.performanceAndAnalytics.rawValue].value = isOn
        case .save:
            save()
        }
    }
    
    // MARK: - Private
    
    private func cookieSettings() async {
        do {
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            
            if cookiesBitmap != .essential {
                for (setting, position) in cookieSettingToPosition where cookiesBitmap.contains(setting) {
                    cookiesConfigArray[position.rawValue].value = true
                }
            }
            
            currentCookiesConfigArray = cookiesConfigArray
            
            invokeCommand?(.configCookieSettings(CookiesBitmap(rawValue: bitmap)))
            
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
        
        self.invokeCommand?(.updateFooters(footersArray))
    }
    
    private func save() {
        if !didCookieSettingsChange() {
            self.invokeCommand?(.cookieSettingsSaved)
            return
        }
        
        Task { @MainActor in
            do {
                var cookiesBitmap = CookiesBitmap(rawValue: 0)
                cookiesBitmap.insert(.essential)
                
                for (setting, position) in cookieSettingToPosition where cookiesConfigArray[position.rawValue].value {
                    cookiesBitmap.insert(setting)
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
