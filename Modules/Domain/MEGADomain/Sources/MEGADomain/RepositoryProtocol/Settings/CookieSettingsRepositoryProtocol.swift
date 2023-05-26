import Foundation

public protocol CookieSettingsRepositoryProtocol: RepositoryProtocol {
    func cookieBannerEnabled() -> Bool
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void)
    func setCrashlyticsEnabled(_ bool: Bool)
}
