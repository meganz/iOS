import Foundation

// MARK: - Use case protocol

/// Decides whether Firebase Analytics collection may be enabled.
///
/// Collection is turned on only when BOTH conditions hold:
/// 1. the user gave performance & analytics consent (cookie settings), and
/// 2. the user is in an allowed region (US / Canada / Japan / Korea).
///
/// The region allow-list deliberately excludes EU users to avoid GDPR scope; it is a
/// best-effort mitigation, complemented by the cookie-settings opt-out entry point.
public protocol FirebaseAnalyticsConsentUseCaseProtocol: Sendable {
    /// Force-disable collection. Used at app launch, before consent/region are known.
    func disableCollection()

    /// Enable collection only when `performanceAndAnalyticsConsent` is `true` AND the user is in
    /// an allowed region; otherwise disable it.
    func updateCollection(performanceAndAnalyticsConsent: Bool) async
}

// MARK: - Use case implementation

public struct FirebaseAnalyticsConsentUseCase: FirebaseAnalyticsConsentUseCaseProtocol {
    private let analyticsRepository: any FirebaseAnalyticsRepositoryProtocol
    private let regionRepository: any AnalyticsRegionRepositoryProtocol

    /// Alpha-2 codes for locale, alpha-3 for storefront — both forms listed so no conversion needed.
    private let allowedRegionCodes: Set<String> = ["US", "USA", "CA", "CAN", "JP", "JPN", "KR", "KOR"]

    public init(
        analyticsRepository: some FirebaseAnalyticsRepositoryProtocol,
        regionRepository: some AnalyticsRegionRepositoryProtocol
    ) {
        self.analyticsRepository = analyticsRepository
        self.regionRepository = regionRepository
    }

    public func disableCollection() {
        analyticsRepository.setAnalyticsEnabled(false)
    }

    public func updateCollection(performanceAndAnalyticsConsent consent: Bool) async {
        guard consent else {
            analyticsRepository.setAnalyticsEnabled(false)
            return
        }
        analyticsRepository.setAnalyticsEnabled(await isInAllowedRegion())
    }

    private func isInAllowedRegion() async -> Bool {
        let (storefront, locale) = await regionRepository.currentRegionCodes()
        guard let storefrontCode = storefront?.uppercased(),
              let localeCode = locale?.uppercased() else { return false }
        return allowedRegionCodes.contains(storefrontCode) && allowedRegionCodes.contains(localeCode)
    }
}
