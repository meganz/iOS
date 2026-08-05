import Foundation

/// Reports whether a plan may be bought on the MEGA website, and builds the URL that sells it, already
/// carrying the user's session.
///
/// Declared here rather than depending on `MEGAStoreKit` directly: the module that owns the real
/// implementation adapts its use case to this protocol, so every consumer of this module stays free of
/// StoreKit, and ``ExternalPlanPurchaser`` can be tested without it.
public protocol ExternalPurchaseLinkProviding: Sendable {
    /// Whether the website route is offered to this user at all, which depends on the remote flag and the
    /// storefront, so it can change while a screen is open.
    func shouldProvideExternalPurchase() async -> Bool

    /// - Throws: when no URL can be produced for the plan.
    func externalPurchaseLink(domain: String, path: String, sourceApp: String?, months: Int?) async throws -> URL
}
