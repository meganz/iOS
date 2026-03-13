import Foundation

protocol DailyRecentActionBucketGrouping: Sendable {
    func group(buckets: [RecentActionBucketEntity]) -> [DailyRecentActionBucketGroup]
}

struct DailyRecentActionBucketGrouper: DailyRecentActionBucketGrouping {
    func group(buckets: [RecentActionBucketEntity]) -> [DailyRecentActionBucketGroup] {
        Dictionary(
            grouping: buckets,
            by: { Calendar.current.startOfDay(for: $0.date) }
        )
        .sorted(by: { $0.key > $1.key })
        .map {
            DailyRecentActionBucketGroup(date: $0.key, buckets: $0.value)
        }
    }
}
