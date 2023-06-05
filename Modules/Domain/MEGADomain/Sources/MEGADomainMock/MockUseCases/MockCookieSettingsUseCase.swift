import MEGADomain

public struct MockCookieSettingsUseCase: CookieSettingsUseCaseProtocol {
    let cookieBannerEnable: Bool
    let cookieSettings: (Result<Int, CookieSettingsErrorEntity>)
    let setCookieSettings: (Result<Int, CookieSettingsErrorEntity>)
    
    public init(cookieBannerEnable: Bool = false,
                cookieSettings: Result<Int, CookieSettingsErrorEntity> = .failure(.generic),
                setCookieSettings: Result<Int, CookieSettingsErrorEntity> = .failure(.generic)) {
        self.cookieBannerEnable = cookieBannerEnable
        self.cookieSettings = cookieSettings
        self.setCookieSettings = setCookieSettings
    }
    
    public func cookieBannerEnabled() -> Bool {
        cookieBannerEnable
    }
    
    public func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(cookieSettings)
    }
    
    public func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(setCookieSettings)
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {}
    
    public func setAnalyticsEnabled(_ bool: Bool) {}
}
