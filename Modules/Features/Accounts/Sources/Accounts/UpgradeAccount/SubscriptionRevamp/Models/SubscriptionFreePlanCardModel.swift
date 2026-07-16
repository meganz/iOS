import MEGAL10n
import MEGASwift
/// The optional "Get started with our free plan" card shown on the redesigned
/// subscription pages to users eligible for the free tier.
struct SubscriptionFreePlanCardModel: Equatable {
    let maxStorageSize: Int64

    var cardTitle: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard.title
    }

    var storageTitle: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard
            .Feature.storage(String.memoryStyleString(fromByteCount: maxStorageSize)
                .formattedByteCountString())
    }

    var transferTitle: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard.Feature.two
    }

    var primaryButtonTitle: String {
        Strings.Localizable.SubscriptionPurchase.FreePlanCard.Button.title
    }
}
