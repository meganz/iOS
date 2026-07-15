import Foundation

// [IOS-12185]: Wire actual data to view model
@MainActor
final class SubscriptionPlanCardsViewModel {
    let cards: [SubscriptionPlanCardModel]

    init(cards: [SubscriptionPlanCardModel] = SubscriptionRevampMockData.planCards) {
        self.cards = cards
    }
}
