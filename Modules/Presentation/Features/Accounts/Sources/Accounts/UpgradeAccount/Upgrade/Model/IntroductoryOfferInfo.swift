import Foundation
import MEGADomain

public struct IntroductoryOfferInfo {
    public let fullPrice: Decimal
    public let formattedFullPrice: String
    public let introPrice: Decimal
    public let formattedIntroPrice: String
    public let formattedIntroPricePerMonth: String
    public let period: IntroductoryOfferEntity.SubscriptionPeriod
}
