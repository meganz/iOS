import MEGAAssets
import MEGAL10n
import MEGAUIComponent
import SwiftUI

enum AlbumSortOptionsFactory {
    static var iconsByDirection: [MEGAUIComponent.SortOrder.SortDirection: Image] {
        [.ascending: MEGAAssets.Image.arrowUp, .descending: MEGAAssets.Image.arrowDown]
    }

    static func makeAll() -> [SortOption] {
        var options: [SortOption] = []
        appendSortOptions(
            for: .lastModified,
            title: Strings.Localizable.Media.PhotoLibrary.Album.Sorting.date,
            to: &options
        )

        return options
    }

    private static func appendSortOptions(
        for key: MEGAUIComponent.SortOrder.Key,
        title: String,
        to options: inout [SortOption]
    ) {
        // Descending first (Newest)
        options.append(
            SortOption(
                sortOrder: SortOrder(key: key, direction: .descending),
                title: title,
                iconsByDirection: iconsByDirection
            )
        )
        // Ascending second (Oldest)
        options.append(
            SortOption(
                sortOrder: SortOrder(key: key, direction: .ascending),
                title: title,
                iconsByDirection: iconsByDirection
            )
        )
    }
}
