import Foundation

/// Provides best-effort region signals used to gate analytics collection by country.
///
/// Returns both the App Store storefront country (alpha-3, e.g. `USA`) and the device
/// locale region (alpha-2, e.g. `US`) independently so callers can apply AND/OR logic.
/// Either value may be `nil` when the respective signal is unavailable.
public protocol AnalyticsRegionRepositoryProtocol: RepositoryProtocol, Sendable {
    func currentRegionCodes() async -> (storefront: String?, locale: String?)
}
