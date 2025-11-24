import MEGAAssets
import MEGAL10n
import Search
import SwiftUI

enum SearchResultsSortOptionFactory {
    static var iconsByDirection: [SortOrderEntity.Direction: Image] {
        [.ascending: MEGAAssets.Image.arrowUp, .descending: MEGAAssets.Image.arrowDown]
    }
    
    static func makeAll(
        excludedKeys: Set<SortOrderEntity.Key> = [
            .shareCreated,
            .linkCreated
        ]
    ) -> [SearchResultsSortOption] {
        var options: [SearchResultsSortOption] = []
        
        appendSortOptions(
            for: .name,
            title: Strings.Localizable.Sorting.Name.title,
            include: excludedKeys.notContains(.name),
            to: &options
        )
        
        appendSortOptions(
            for: .favourite,
            title: Strings.Localizable.Sorting.Favourite.title,
            include: excludedKeys.notContains(.favourite),
            to: &options
        )
        
        appendSortOptions(
            for: .label,
            title: Strings.Localizable.CloudDrive.Sort.label,
            include: excludedKeys.notContains(.label),
            to: &options
        )
        
        appendSortOptions(
            for: .shareCreated,
            title: Strings.Localizable.Sorting.ShareCreated.title,
            include: excludedKeys.notContains(.shareCreated),
            to: &options
        )
        
        appendSortOptions(
            for: .linkCreated,
            title: Strings.Localizable.Sorting.LinkCreated.title,
            include: excludedKeys.notContains(.linkCreated),
            to: &options
        )
        
        appendSortOptions(
            for: .dateAdded,
            title: Strings.Localizable.Sorting.DateAdded.title,
            include: excludedKeys.notContains(.dateAdded),
            to: &options
        )
        
        appendSortOptions(
            for: .lastModified,
            title: Strings.Localizable.Sorting.LastModified.title,
            include: excludedKeys.notContains(.lastModified),
            to: &options
        )
        
        appendSortOptions(
            for: .size,
            title: Strings.Localizable.Sorting.Size.title,
            include: excludedKeys.notContains(.size),
            to: &options
        )
        
        return options
    }
    
    private static func appendSortOptions(
        for key: SortOrderEntity.Key,
        title: String,
        include: Bool = true,
        to options: inout [SearchResultsSortOption]
    ) {
        guard include else { return }
        options.append(
            .init(
                sortOrder: .init(key: key),
                title: title,
                iconsByDirection: iconsByDirection
            )
        )
        options.append(
            .init(
                sortOrder: .init(key: key, direction: .descending),
                title: title,
                iconsByDirection: iconsByDirection
            )
        )
    }
}
