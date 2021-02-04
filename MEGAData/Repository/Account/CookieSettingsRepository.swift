
import Foundation
import FirebaseCrashlytics

struct CookieSettingsRepository: CookieSettingsRepositoryProtocol {
    private let sdk: MEGASdk
    private let crashlytics: Crashlytics = Crashlytics.crashlytics()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func cookieBannerEnabled() -> Bool {
        return sdk.cookieBannerEnabled()
    }
    
    func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.cookieSettings(with: MEGAGenericRequestDelegate { (request, error) in
            if error.type == .apiOk {
                completion(.success(request.numDetails))
            } else {
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
        sdk.setCookieSettings(settings, delegate: MEGAGenericRequestDelegate { (request, error) in
            if error.type == .apiOk {
                completion(.success(request.numDetails))
            } else {
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
