@testable import Accounts
import Foundation
import Testing

@Suite("SubscriptionCountdown")
struct SubscriptionCountdownTests {
    @Test(arguments: [
        (TimeInterval((28 * 24 + 12) * 3600 + 60), SubscriptionCountdown(days: 28, hours: 12, minutes: 1)),
        (TimeInterval(-1000), SubscriptionCountdown(days: 0, hours: 0, minutes: 0)),
        (TimeInterval(59), SubscriptionCountdown(days: 0, hours: 0, minutes: 0))
    ])
    func computesRemaining(offset: TimeInterval, expected: SubscriptionCountdown) {
        let now = Date(timeIntervalSince1970: 0)
        let deadline = now.addingTimeInterval(offset)

        let countdown = SubscriptionCountdown.remaining(until: deadline, from: now)

        #expect(countdown == expected)
    }
}
