import StoreKit

/// Redeemability checks for a customer's promotional and introductory offers.
public protocol StoreKitSubscriptionEligibilityChecking: Sendable {
    func canRedeemPromotionalOffer() async -> Bool
    func activeSubscriptionGroupIDs() async -> Set<String>
    func isIntroductoryOfferRedeemable(
        for subscription: Product.SubscriptionInfo,
        activeGroupIDs: Set<String>
    ) async -> Bool
}

/// Redeemability checkers for promotional and introductory offer
public struct StoreKitSubscriptionEligibility: StoreKitSubscriptionEligibilityChecking {
    public init() {}

    /// Check whether the current user can redeem a promotional offer.
    /// Underlying rule: Only past or current subscribers can redeem promotional offers
    public func canRedeemPromotionalOffer() async -> Bool {
        for await result in StoreKit.Transaction.all {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil else { continue }
            return true
        }
        return false
    }

    /// The subscription groups the customer currently holds an active subscription in.
    public func activeSubscriptionGroupIDs() async -> Set<String> {
        var groupIDs: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable,
                  let groupID = transaction.subscriptionGroupID else { continue }
            groupIDs.insert(groupID)
        }
        return groupIDs
    }

    /// Check whether the current user can apply this subscription's introductory offer at checkout.
    ///
    /// Previously we only check for `subscription.isEligibleForIntroOffer` which is not enough because
    /// `subscription.isEligibleForIntroOffer` can be true even when user is not qualified (aka when user is still having an active subscription).
    /// The correct method is to check `subscription.isEligibleForIntroOffer` and `activeGroupIDs.contains()` together
    public func isIntroductoryOfferRedeemable(
        for subscription: Product.SubscriptionInfo,
        activeGroupIDs: Set<String>
    ) async -> Bool {
        guard subscription.introductoryOffer != nil,
              await subscription.isEligibleForIntroOffer else {
            return false
        }
        return !activeGroupIDs.contains(subscription.subscriptionGroupID)
    }
}
