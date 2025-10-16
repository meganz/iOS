import MEGAAssets
import MEGAL10n
import Search
import SwiftUI

enum SearchResultsSortOptionFactory {
    static var iconsByDirection: [SortOrderEntity.Direction: Image] {
        [.ascending: MEGAAssets.Image.arrowUp, .descending: MEGAAssets.Image.arrowDown]
    }
    
    static func makeAll() -> [SearchResultsSortOption] {
        [
            .init(
                sortOrder: .init(key: .name),
                title: Strings.Localizable.Sorting.Name.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .name, direction: .descending),
                title: Strings.Localizable.Sorting.Name.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .favourite),
                title: Strings.Localizable.Sorting.Favourite.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .favourite, direction: .descending),
                title: Strings.Localizable.Sorting.Favourite.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .label),
                title: Strings.Localizable.CloudDrive.Sort.label,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .label, direction: .descending),
                title: Strings.Localizable.CloudDrive.Sort.label,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .dateAdded),
                title: Strings.Localizable.Sorting.DateAdded.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .dateAdded, direction: .descending),
                title: Strings.Localizable.Sorting.DateAdded.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .lastModified),
                title: Strings.Localizable.Sorting.LastModified.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .lastModified, direction: .descending),
                title: Strings.Localizable.Sorting.LastModified.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .size),
                title: Strings.Localizable.Sorting.Size.title,
                iconsByDirection: iconsByDirection
            ),
            .init(
                sortOrder: .init(key: .size, direction: .descending),
                title: Strings.Localizable.Sorting.Size.title,
                iconsByDirection: iconsByDirection
            )
        ]
    }
}
