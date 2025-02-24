import Foundation
import MEGAL10n
import Search

protocol RecentListHeaderViewModelFactoryProtocol {
    func buildIfNeeded(
        for nodeSource: NodeSource
    ) -> ListHeaderViewModel?
}

// for recent action buckets (ie Recents mode of Cloud Drive) this builds a view model
// of the table view (list) section header
// containing :
// 1. date of creation of the bucket
// 2. type of the bucket (initial update or first upload)
// 3. name of the parent node
// for normal non-recent action bucket, nil view model is returned
struct RecentListHeaderViewModelFactory: RecentListHeaderViewModelFactoryProtocol {
    let calendar: Calendar
    // extracted this bit of the data formatting so that it can be
    // made stable in unit tests (default implementation is static Objc
    // and does not allow for injecting of hardcoded locale)
    let mediumStyleFormatter: (Date) -> String
    
    func buildIfNeeded(
        for nodeSource: NodeSource
    ) -> ListHeaderViewModel? {
        guard case let .recentActionBucket(bucket) = nodeSource else { return nil }
        
        func dateString(_ bucket: any RecentActionBucket) -> String {
            guard let date = bucket.timestamp else { return "" }
            if date.isToday(on: calendar) {
                return Strings.Localizable.today
            }
            if date.isYesterday(on: calendar) {
                return Strings.Localizable.yesterday
            }
            return mediumStyleFormatter(date)
        }
        
        func icon(_ bucket: any RecentActionBucket) -> UIImage {
            if bucket.isUpdate {
                UIImage.versioned
            } else {
                UIImage.recentUpload
            }
        }
        
        let nodeName: String = bucket.parentNode()?.name.uppercased() ?? ""
        
        return ListHeaderViewModel(
            leadingText: String("\(nodeName) •"),
            icon: icon(bucket),
            trailingText: dateString(bucket).uppercased()
        )
    }
}
