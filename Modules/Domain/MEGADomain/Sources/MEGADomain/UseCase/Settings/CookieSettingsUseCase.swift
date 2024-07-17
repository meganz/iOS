import Foundation

// MARK: - Use case protocol
public protocol CookieSettingsUseCaseProtocol: Sendable {
    func cookieBannerEnabled() -> Bool
    
    func cookieSettings() async throws -> Int
    
    func setCookieSettings(with settings: Int) async throws -> Int
    
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
    
    public func cookieSettings() async throws -> Int {
        try await repository.cookieSettings()
    }
    
    public func setCookieSettings(with settings: Int) async throws -> Int {
        try await repository.setCookieSettings(with: settings)
    }
    
    public func setCrashlyticsEnabled(_ bool: Bool) {
        repository.setCrashlyticsEnabled(bool)
    }
}
