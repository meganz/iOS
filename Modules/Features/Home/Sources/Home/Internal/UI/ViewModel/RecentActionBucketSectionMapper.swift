import Foundation
import MEGAL10n

struct RecentActionBucketSectionMapper {
    func map(bucketGroups: [DailyRecentActionBucketGroup]) -> [RecentActionBucketSection] {
        bucketGroups.map {
            RecentActionBucketSection(
                title: title(for: $0.date),
                buckets: $0.buckets
            )
        }
    }
    
    private func title(for date: Date) -> String {
        let calendar = Calendar.current
        return if calendar.isDateInToday(date) {
            Strings.Localizable.today
        } else if calendar.isDateInYesterday(date) {
            Strings.Localizable.yesterday
        } else {
            date.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.abbreviated)
                    .year()
            )
        }
    }
}
