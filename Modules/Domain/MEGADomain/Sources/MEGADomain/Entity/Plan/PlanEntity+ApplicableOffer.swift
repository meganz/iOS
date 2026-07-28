public extension PlanEntity {
    var applicableOffer: SubscriptionOfferEntity? {
        if let introductoryOffer {
            return introductoryOffer
        }

        if hasValidPromotionalOffer, let promotionalOffer {
            return promotionalOffer
        }

        return nil
    }
}
