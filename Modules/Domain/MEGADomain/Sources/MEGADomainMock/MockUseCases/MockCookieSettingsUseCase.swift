import MEGADomain
import MEGASwift

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
    
    public func cookieSettings() async throws -> Int {
        return try await withAsyncThrowingValue { continuation in
            cookieSettings { result in
                handleCookiesCompletion(result, continuation: continuation)
            }
        }
    }
    
    private func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(cookieSettings)
    }
    
    public func setCookieSettings(with settings: Int) async throws -> Int {
        return try await withAsyncThrowingValue { continuation in
            setCookieSettings(with: settings) { result in
                handleCookiesCompletion(result, continuation: continuation)
            }
        }
    }
    
    private func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(setCookieSettings)
    }
    
    private func handleCookiesCompletion<T>(_ result: Result<T, CookieSettingsErrorEntity>, continuation: @escaping (Result<T, any Error>) -> Void) {
        switch result {
        case .success(let value):
            continuation(.success(value))
        case .failure(let error):
            continuation(.failure(error))
        }
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {}
    
    public func setAnalyticsEnabled(_ bool: Bool) {}
}
