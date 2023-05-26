import Foundation

// MARK: - Use case protocol
public protocol CookieSettingsUseCaseProtocol {
    func cookieBannerEnabled() -> Bool
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    
    func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    
    func setCrashlyticsEnabled(_ bool: Bool)
}

// MARK: - Use case implementation
public struct CookieSettingsUseCase<T: CookieSettingsRepositoryProtocol>: CookieSettingsUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func cookieBannerEnabled() -> Bool {
        repository.cookieBannerEnabled()
    }
    
    public func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        repository.cookieSettings(completion: completion)
    }
    
    public func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        repository.setCookieSettings(with: settings, completion: completion)
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {
        repository.setCrashlyticsEnabled(bool)
    }
}
