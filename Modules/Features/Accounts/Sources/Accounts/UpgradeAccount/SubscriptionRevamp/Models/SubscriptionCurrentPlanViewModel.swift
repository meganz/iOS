import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n

struct SubscriptionCurrentPlanViewModel: Equatable {
    enum Status: Equatable {
        case renews(Date)
        case expires(Date)
    }

    let name: String
    let cycle: SubscriptionCycleEntity
    let status: Status?
    let durationMonths: Int?
    let badgeTitle: String?
    let now: Date

    init(
        name: String,
        cycle: SubscriptionCycleEntity,
        status: Status? = nil,
        durationMonths: Int? = nil,
        badgeTitle: String? = nil,
        now: Date = Date()
    ) {
        self.name = name
        self.cycle = cycle
        self.status = status
        self.durationMonths = durationMonths
        self.badgeTitle = badgeTitle
        self.now = now
    }

    // MARK: - Display

    var cycleText: String? {
        switch cycle {
        case .yearly: Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.yearly
        case .monthly: Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.monthly
        case .none: durationMonths.map { Strings.Localizable.General.Format.RetentionPeriod.month($0) }
        }
    }

    var statusText: String? {
        switch status {
        case .renews(let date): renewalText(for: date)
        case .expires(let date): Strings.Localizable.Account.Profile.Expiry.future(formattedDate(date))
        case nil: nil
        }
    }

    // MARK: - Date formatting

    private func renewalText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return Strings.Localizable.Account.Profile.Renewal.today
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return Strings.Localizable.Account.Profile.Renewal.tomorrow
        }
        return Strings.Localizable.Account.Profile.Renewal.future(formattedDate(date))
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let daysDifference = calendar.dateComponents([.day], from: startOfToday, to: date).day ?? .max
        let formatter: any DateFormatting
        if abs(daysDifference) <= 7 {
            formatter = DateFormatter.dateMediumWithWeekday()
        } else {
            formatter = DateFormatter.dateMedium()
        }
        return formatter.localisedString(from: date)
    }
}
