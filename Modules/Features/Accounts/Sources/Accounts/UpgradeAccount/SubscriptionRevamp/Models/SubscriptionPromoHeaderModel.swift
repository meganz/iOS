import Foundation

struct SubscriptionPromoHeaderModel: Equatable {
    let tag: String
    let title: String
    let subtitle: String
    let validUntil: String
    let deadline: Date

    init(
        tag: String,
        title: String,
        subtitle: String,
        validUntil: String,
        deadline: Date
    ) {
        self.tag = tag
        self.title = title
        self.subtitle = subtitle
        self.validUntil = validUntil
        self.deadline = deadline
    }
}
