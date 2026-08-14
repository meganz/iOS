import Foundation
import MEGADomain
import MEGAPreference

/// Gates how often the promotional offer landing dialog may open itself on app open.
///
/// An allowance speaks for one campaign on one account: it is built once the offer to advertise is known, and
/// answers for that offer only, so the campaign that was gated is always the campaign that gets recorded.
public protocol PromoDialogReshowAllowing: Sendable {
    /// Whether the campaign this allowance was built for may be advertised on this app open.
    var isAvailable: Bool { get }
    /// Records that the dialog was shown for that campaign. Only call this once it actually appeared on screen.
    func consume()
}

struct PromoDialogReshowAllowance: PromoDialogReshowAllowing {
    /// The dedicated suite this allowance stores into, kept out of `UserDefaults.standard` so the
    /// campaign state can be inspected, and wiped, on its own.
    static let suiteName = "PromoLandingDialogReshow"

    private let offer: MobileOfferEntity
    private let currentDate: @Sendable () -> Date

    @PreferenceWrapper<Date?, PromoDialogReshowKey>
    private var lastShownDate: Date?

    init(
        accountHandle: HandleEntity,
        offer: MobileOfferEntity,
        preferenceUseCase: some PreferenceUseCaseProtocol,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.offer = offer
        self.currentDate = currentDate
        _lastShownDate = PreferenceWrapper(
            key: PromoDialogReshowKey(accountHandle: accountHandle, campaignId: offer.campaignId),
            defaultValue: nil,
            useCase: preferenceUseCase
        )
    }

    var isAvailable: Bool {
        guard let lastShownDate else { return true }
        guard let reshowTimeout = offer.reshowTimeout else { return false }
        return currentDate().timeIntervalSince(lastShownDate) >= reshowTimeout
    }

    func consume() {
        lastShownDate = currentDate()
    }
}

// MARK: - Production instance
extension PromoDialogReshowAllowance {
    /// The app-open allowance for `offer` on `accountHandle`, backed by its own `UserDefaults` suite.
    static func onAppOpen(accountHandle: HandleEntity, offer: MobileOfferEntity) -> PromoDialogReshowAllowance {
        PromoDialogReshowAllowance(
            accountHandle: accountHandle,
            offer: offer,
            preferenceUseCase: PreferenceUseCase(
                repository: PreferenceRepository(userDefaults: UserDefaults(suiteName: suiteName) ?? .standard)
            )
        )
    }
}
