import MEGADomain
import MEGASwift

public struct MockCookieSettingsRepository: CookieSettingsRepositoryProtocol {
    public static var newRepo: MockCookieSettingsRepository {
        MockCookieSettingsRepository()
    }
    
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
        try await withAsyncThrowingValue { continuation in
            self.cookieSettings { result in
                switch result {
                case .success(let value):
                    continuation(.success(value))
                case .failure(let error):
                    continuation(.failure(error))
                }
            }
        }
    }
    
    private func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(cookieSettings)
    }
    
    public func setCookieSettings(with settings: Int) async throws -> Int {
        try await withAsyncThrowingValue { continuation in
            self.setCookieSettings(with: settings) { result in
                switch result {
                case .success(let value):
                    continuation(.success(value))
                case .failure(let error):
                    continuation(.failure(error))
                }
            }
        }
    }
    
    private func setCookieSettings(with settings: Int, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        completion(setCookieSettings)
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {}
}
