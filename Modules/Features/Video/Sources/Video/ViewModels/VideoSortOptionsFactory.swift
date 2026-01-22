import MEGAAssets
import MEGAL10n
import MEGAUIComponent
import SwiftUI

enum VideoSortOptionsFactory {
    static var iconsByDirection: [MEGAUIComponent.SortOrder.SortDirection: Image] {
        [.ascending: MEGAAssets.Image.arrowUp, .descending: MEGAAssets.Image.arrowDown]
    }

    static func makeAll() -> [SortOption] {
        var options: [SortOption] = []

        // Name sorting
        appendSortOptions(
            for: .name,
            title: Strings.Localizable.Sorting.Name.title,
            to: &options
        )

        // Size sorting
        appendSortOptions(
            for: .size,
            title: Strings.Localizable.Sorting.Size.title,
            to: &options
        )

        // Last Modified sorting
        appendSortOptions(
            for: .lastModified,
            title: Strings.Localizable.Sorting.LastModified.title,
            to: &options
        )

        // Label sorting
        appendSortOptions(
            for: .label,
            title: Strings.Localizable.CloudDrive.Sort.label,
            to: &options
        )

        // Favourite sorting
        appendSortOptions(
            for: .favourite,
            title: Strings.Localizable.favourite,
            to: &options
        )

        return options
    }

    private static func appendSortOptions(
        for key: MEGAUIComponent.SortOrder.Key,
        title: String,
        to options: inout [SortOption]
    ) {
        options.append(
            SortOption(
                key: key,
                localizedTitle: title
            )
        )
    }
}
