import MEGADomain

public struct MockAnalyticsRegionRepository: AnalyticsRegionRepositoryProtocol {
    public static var newRepo: MockAnalyticsRegionRepository {
        MockAnalyticsRegionRepository()
    }

    private let storefrontCode: String?
    private let localeCode: String?

    public init(storefrontCode: String? = nil, localeCode: String? = nil) {
        self.storefrontCode = storefrontCode
        self.localeCode = localeCode
    }

    public func currentRegionCodes() async -> (storefront: String?, locale: String?) {
        (storefrontCode, localeCode)
    }
}
