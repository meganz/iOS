import Foundation
import MEGADomain
import MEGAUIComponent

/// Static mock data feeding the composed subscription page previews.
///
/// The promo/standard pages are wired to real data; this exists only so the
/// preview canvas can render card and header states without touching real data.
enum SubscriptionRevampMockData {
    static var planCards: [SubscriptionPlanCardModel] {
        [
            SubscriptionPlanCardModel(
                title: "Pro Lite",
                price: .yearly(.init(pricePerMonth: "€3.33/month", billingCaption: "€40.01 charged yearly")),
                storage: "400 GB storage",
                transfer: "1 TB transfer",
                ribbonText: "Best value",
                isPrimaryAction: true
            ),
            SubscriptionPlanCardModel(
                title: "Pro I",
                price: .monthly(.init(pricePerMonth: "€9.99/month")),
                storage: "2 TB storage",
                transfer: "2 TB transfer"
            ),
            SubscriptionPlanCardModel(
                title: "Pro II",
                price: .discountMonthly(.init(
                    priceLine: "[A]€19.99[/A] €14.99/month",
                    billingCaption: "Discount price for the first 12 months"
                )),
                storage: "8 TB storage",
                transfer: "8 TB transfer"
            )
        ]
    }

    static var freePlanCard: SubscriptionFreePlanCardModel {
        SubscriptionFreePlanCardModel(
            maxStorageSize: 21474836480,
            isExistingFreeAccount: false
        )
    }
}
