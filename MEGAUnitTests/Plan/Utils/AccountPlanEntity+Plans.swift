@testable import MEGA
import MEGADomain

public extension PlanEntity {
    static var freePlan = PlanEntity(type: .free, name: "Free")

    static var proLite_monthly = PlanEntity(
        type: .lite,
        name: "Pro lite",
        subscriptionCycle: .monthly,
        apiPrice: .sample(1),
        appStorePrice: .sample(1)
    )

    static var proLite_yearly = PlanEntity(
        type: .lite,
        name: "Pro lite",
        subscriptionCycle: .yearly,
        apiPrice: .sample(2),
        appStorePrice: .sample(2)
    )

    static var proI_monthly = PlanEntity(
        type: .proI,
        name: "Pro I",
        subscriptionCycle: .monthly,
        storageLimit: 3072,
        storage: "3 TB",
        apiPrice: .sample(3),
        appStorePrice: .sample(3)
    )

    static var proI_yearly = PlanEntity(
        type: .proI,
        name: "Pro I",
        subscriptionCycle: .yearly,
        storageLimit: 3072,
        storage: "3 TB",
        apiPrice: .sample(4),
        appStorePrice: .sample(4)
    )

    static var proII_monthly = PlanEntity(
        type: .proII,
        name: "Pro II",
        subscriptionCycle: .monthly,
        storageLimit: 10240,
        storage: "10 TB",
        apiPrice: .sample(5),
        appStorePrice: .sample(5)
    )

    static var proII_yearly = PlanEntity(
        type: .proII,
        name: "Pro II",
        subscriptionCycle: .yearly,
        storageLimit: 10240,
        storage: "10 TB",
        apiPrice: .sample(6),
        appStorePrice: .sample(6)
    )

    static var proIII_monthly = PlanEntity(
        type: .proIII,
        name: "Pro III",
        subscriptionCycle: .monthly,
        storageLimit: 20480,
        storage: "20 TB",
        apiPrice: .sample(7),
        appStorePrice: .sample(7)
    )
    
    static var proIII_yearly = PlanEntity(
        type: .proIII,
        name: "Pro III",
        subscriptionCycle: .yearly,
        storageLimit: 20480,
        storage: "20 TB",
        apiPrice: .sample(8),
        appStorePrice: .sample(8)
    )
}

extension PlanPriceEntity {
    static func sample(
        _ price: Decimal,
        currency: String = "USD"
    ) -> PlanPriceEntity {
        PlanPriceEntity(
            price: price,
            formattedPrice: "$\(price)",
            currency: currency
        )
    }
}
