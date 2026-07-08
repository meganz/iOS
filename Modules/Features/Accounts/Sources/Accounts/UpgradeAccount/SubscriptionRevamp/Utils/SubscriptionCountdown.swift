import Foundation

public struct SubscriptionCountdown: Equatable, Sendable {
    public let days: Int
    public let hours: Int
    public let minutes: Int

    public init(days: Int, hours: Int, minutes: Int) {
        self.days = days
        self.hours = hours
        self.minutes = minutes
    }

    public static func remaining(until deadline: Date, from now: Date) -> SubscriptionCountdown {
        let interval = max(0, deadline.timeIntervalSince(now))
        let totalMinutes = Int(interval / 60)
        return SubscriptionCountdown(
            days: totalMinutes / (60 * 24),
            hours: (totalMinutes % (60 * 24)) / 60,
            minutes: totalMinutes % 60
        )
    }
}
