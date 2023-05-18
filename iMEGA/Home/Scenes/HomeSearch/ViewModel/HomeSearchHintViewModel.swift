import Foundation

struct HomeSearchHintViewModel: Comparable, Hashable {

    let text: String

    let searchTime: Date

    static func < (lhs: HomeSearchHintViewModel, rhs: HomeSearchHintViewModel) -> Bool {
        return lhs.searchTime < rhs.searchTime
    }
}

extension HomeSearchHintViewModel: Aggregatable {

    var title: String {
        DateFormatter.dateRelativeMedium().localisedString(from: key)
    }

    var key: Date {
        Calendar.current.startOfDay(for: searchTime)
    }
}
