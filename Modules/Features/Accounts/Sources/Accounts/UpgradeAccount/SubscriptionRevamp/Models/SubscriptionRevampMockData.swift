import MEGAAssets
import MEGADomain
import SwiftUI

/// Static mock data feeding the composed subscription page.
///
/// All copy is placeholder and marked to be localized later. This exists only so
/// the redesigned page can render every design state without touching real data.
enum SubscriptionRevampMockData {
    static let cycleOptions: [SubscriptionCycleEntity] = [.monthly, .yearly]

    static let savingText = "Save up to 16%" // To be localized later
    
    static var currentPlan: SubscriptionCurrentPlanViewModel {
        SubscriptionCurrentPlanViewModel(
            plan: PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly),
            status: .renews
        )
    }

    static func cycleTitle(_ cycle: SubscriptionCycleEntity) -> String {
        switch cycle {
        case .monthly: "Monthly" // To be localized later
        case .yearly: "Yearly" // To be localized later
        case .none: "" // To be localized later
        }
    }

    static var planCards: [SubscriptionPlanCardModel] {
        [
            SubscriptionPlanCardModel(
                title: "Pro Lite", // To be localized later
                price: .yearly(price: "€3.33/month", billing: "€40.01 charged yearly"), // To be localized later
                storage: "400 GB storage", // To be localized later
                transfer: "1 TB transfer", // To be localized later
                ribbonText: "Best value", // To be localized later
                isPrimaryAction: true
            ),
            SubscriptionPlanCardModel(
                title: "Pro I", // To be localized later
                price: .monthly(price: "€9.99/month"), // To be localized later
                storage: "2 TB storage", // To be localized later
                transfer: "2 TB transfer" // To be localized later
            ),
            SubscriptionPlanCardModel(
                title: "Pro II", // To be localized later
                price: .discount(
                    originalPrice: "€19.99", // To be localized later
                    discountedPrice: "€14.99/month", // To be localized later
                    description: "Discount price for the first 12 months" // To be localized later
                ),
                storage: "8 TB storage", // To be localized later
                transfer: "8 TB transfer" // To be localized later
            )
        ]
    }

    static var promoPlanCard: SubscriptionRevampPromoPlanCardModel {
        SubscriptionRevampPromoPlanCardModel(
            ribbonText: "6-month Flash Deal: 50% off", // To be localized later
            title: "Pro I", // To be localized later
            originalPrice: "€9.99", // To be localized later
            discountedPrice: "€4.99/month for 6 months", // To be localized later
            priceDescription: "Billed at €4.99/month for the first 6 months, €9.99/month after", // To be localized later
            storage: "2 TB cloud storage", // To be localized later
            transfer: "2 TB transfer", // To be localized later
            buttonTitle: "Get Pro I" // To be localized later
        )
    }

    static var freePlanCard: SubscriptionFreePlanCardModel {
        SubscriptionFreePlanCardModel(
            maxStorageSize: 21474836480
        )
    }

    static var promoHeader: SubscriptionPromoHeaderModel {
        SubscriptionPromoHeaderModel(
            tag: "Special offer", // To be localized later
            title: "Black Friday - 50% off", // To be localized later
            subtitle: "€119.88 for the first year", // To be localized later
            validUntil: "Offer ends on 11 August 2026", // To be localized later, keep consistent with `deadline`
            deadline: Date.now.addingTimeInterval(60 * 60 * 24 * 28)
        )
    }
}
