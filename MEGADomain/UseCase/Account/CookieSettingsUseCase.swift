
import Foundation

// MARK: - Use case protocol
protocol CookieSettingsUseCaseProtocol {
    func cookieBannerEnabled() -> Bool
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    
    func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    
    func setCrashlyticsEnabled(_ bool: Bool) -> Void
}

// MARK: - Use case implementation
struct CookieSettingsUseCase<T: CookieSettingsRepositoryProtocol>: CookieSettingsUseCaseProtocol {
    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
    
    func cookieBannerEnabled() -> Bool {
        repository.cookieBannerEnabled()
    }
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        repository.cookieSettings(completion: completion)
    }
    
    func setCookieSettings(with settings: NSInteger, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        repository.setCookieSettings(with: settings, completion: completion)
    }
    
    func setCrashlyticsEnabled(_ bool: Bool) -> Void {
        repository.setCrashlyticsEnabled(bool)
    }
}
