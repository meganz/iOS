import Foundation

public protocol CookieSettingsRepositoryProtocol: RepositoryProtocol, Sendable {
    func cookieBannerEnabled() -> Bool
    func cookieSettings() async throws -> Int
    func setCookieSettings(with settings: Int) async throws -> Int
    func setCrashlyticsEnabled(_ bool: Bool)
}
