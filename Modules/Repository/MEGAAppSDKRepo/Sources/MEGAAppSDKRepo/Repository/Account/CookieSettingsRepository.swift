@preconcurrency import FirebaseCrashlytics
import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

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
    
    public func cookieSettings() async throws -> Int {
        try await withAsyncThrowingValue { continuation in
            cookieSettings { result in
                handleCookieSettingsCompletion(result, continuation: continuation)
            }
        }
    }
    
    public func setCookieSettings(with settings: Int) async throws -> Int {
        try await withAsyncThrowingValue { continuation in
            setCookieSettings(with: settings) { result in
                handleCookieSettingsCompletion(result, continuation: continuation)
            }
        }
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {
        crashlytics.setCrashlyticsCollectionEnabled(bool)
    }
}

extension CookieSettingsRepository {
    
    private func cookieSettings(completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
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
    
    private func setCookieSettings(with settings: NSInteger, completion: @escaping (Result<Int, CookieSettingsErrorEntity>) -> Void) {
        sdk.setCookieSettings(settings, delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.numDetails))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
    
    private func handleCookieSettingsCompletion<T>(_ result: Result<T, CookieSettingsErrorEntity>, continuation: @escaping (Result<T, any Error>) -> Void) {
        switch result {
        case .success(let value):
            continuation(.success(value))
        case .failure(let error):
            continuation(.failure(error))
        }
    }
}
