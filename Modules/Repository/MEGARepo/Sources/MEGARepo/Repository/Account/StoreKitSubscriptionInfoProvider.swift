import StoreKit

/// Reads the App Store's subscription information for a single product.
public protocol StoreKitSubscriptionInfoProviding: Sendable {
    func subscriptionInfo(forProductIdentifier productIdentifier: String) async -> Product.SubscriptionInfo?
}

public struct StoreKitSubscriptionInfoProvider: StoreKitSubscriptionInfoProviding {
    public init() {}

    public func subscriptionInfo(forProductIdentifier productIdentifier: String) async -> Product.SubscriptionInfo? {
        guard let product = try? await Product.products(for: [productIdentifier]).first else { return nil }
        return product.subscription
    }
}
