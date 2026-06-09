import Foundation
import MEGADomain
import StoreKit

/// Resolves the user's region signals for analytics gating.
///
/// Returns both the App Store storefront country (alpha-3, e.g. `USA`) and the device
/// locale region (alpha-2, e.g. `US`) independently. Both are required to be in the
/// allow-list before analytics is enabled.
public struct AnalyticsRegionRepository: AnalyticsRegionRepositoryProtocol {
    public static var newRepo: AnalyticsRegionRepository {
        AnalyticsRegionRepository()
    }

    public init() {}

    public func currentRegionCodes() async -> (storefront: String?, locale: String?) {
        let storefront = await Storefront.current?.countryCode
        let locale = Locale.current.region?.identifier
        return (storefront, locale)
    }
}
