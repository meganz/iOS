
import Foundation
import FirebaseCrashlytics
import MEGADomain
import MEGAData

struct CookieSettingsRepository: CookieSettingsRepositoryProtocol {
    static var newRepo: CookieSettingsRepository {
        CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    private let crashlytics: Crashlytics = Crashlytics.crashlytics()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func cookieBannerEnabled() -> Bool {
        return sdk.cookieBannerEnabled()
    }
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.cookieSettings(with: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                completion(.success(request.numDetails))
            case .failure(let error):
                let cookieSettingsError: CookieSettingsErrorEntity
                switch error.type {
                case .apiEInternal:
                    cookieSettingsError = .invalidBitmap
                    
                case .apiENoent:
                    cookieSettingsError = .bitmapNotSet
                    
                default:
                    cookieSettingsError = .generic
                }
                
                completion(.failure(cookieSettingsError))
            }
        })
    }
    
    func setCookieSettings(with settings: NSInteger, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.setCookieSettings(settings, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                completion(.success(request.numDetails))
            case .failure(let error):
                let cookieSettingsError: CookieSettingsErrorEntity
                switch error.type {
                default:
                    cookieSettingsError = .generic
                }
                
                completion(.failure(cookieSettingsError))
            }
        })
    }
    
    func setCrashlyticsEnabled(_ bool: Bool) {
        crashlytics.setCrashlyticsCollectionEnabled(bool)
    }
}
