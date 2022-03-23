
@testable import MEGA

struct MockCookieSettingsUseCase: CookieSettingsUseCaseProtocol {
    var cookieBannerEnable: Bool = false
    var cookieSettings: (Result<Int, CookieSettingsErrorEntity>) = .failure(.generic)
    var setCookieSettings: (Result<Int, CookieSettingsErrorEntity>) = .failure(.generic)
    
    func cookieBannerEnabled() -> Bool {
        cookieBannerEnable
    }
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(cookieSettings)
    }
    
    func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(setCookieSettings)
    }
    
    func setCrashlyticsEnabled(_ bool: Bool) {}
    
    func setAnalyticsEnabled(_ bool: Bool) {}
}
