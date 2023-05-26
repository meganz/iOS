
import Foundation
import FirebaseCrashlytics
import MEGADomain
import MEGASdk

public struct CookieSettingsRepository: CookieSettingsRepositoryProtocol {
    public static var newRepo: CookieSettingsRepository {
        CookieSettingsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    private let crashlytics: Crashlytics = Crashlytics.crashlytics()
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func cookieBannerEnabled() -> Bool {
        return sdk.cookieBannerEnabled()
    }
    
    public func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.cookieSettings(with: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.numDetails))
            case .failure(let error):
                switch error.type {
                case .apiEInternal:
                    completion(.failure(.invalidBitmap))
                case .apiENoent:
                    completion(.failure(.bitmapNotSet))
                default:
                    completion(.failure(.generic))
                }
            }
        })
    }
    
    public func setCookieSettings(with settings: NSInteger, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.setCookieSettings(settings, delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.numDetails))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {
        crashlytics.setCrashlyticsCollectionEnabled(bool)
    }
}
