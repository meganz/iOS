import MEGAAppPresentation
import MEGAL10n
import MEGAUIComponent

extension SortHeaderConfig {
    static var folderLink: SortHeaderConfig {
        let keys: [MEGAUIComponent.SortOrder.Key] = [
            .name,
            .favourite,
            .label,
            .lastModified,
            .size
        ]
        
        return SortHeaderConfig(
            title: Strings.Localizable.sortTitle,
            options: keys.sortOptions
        )
    }
}
